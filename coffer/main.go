package main

import (
	"bytes"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"math"
	"math/rand"
	"mime/multipart"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	log "github.com/schollz/logger"
)

const MaxBytesPerFile = 2000000000 // 2 GB
const ContentDirectory = "uploads"

var indexHTML []byte

type MetadataInfo struct {
	File         string
	OriginalFile string
	Band         string
	Artist       string
	OtherInfo    string
	BPM          string
	Date         string
}

var metadataSaved map[string]MetadataInfo

func main() {
	port := 8730
	metadataSaved = make(map[string]MetadataInfo)
	os.MkdirAll(ContentDirectory, 0644)
	log.SetLevel("debug")
	log.Infof("listening on :%d", port)
	r := http.NewServeMux()
	s := &http.Server{
		Addr:         fmt.Sprintf(":%d", port),
		ReadTimeout:  0,
		WriteTimeout: 0,
		IdleTimeout:  0,
		Handler:      r,
	}
	r.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./static"))))
	r.HandleFunc("/", handler)
	s.ListenAndServe()
}

func handler(w http.ResponseWriter, r *http.Request) {
	t := time.Now().UTC()
	err := handle(w, r)
	if err != nil {
		log.Error(err)
	}
	log.Infof("%v %v %v %s\n", r.RemoteAddr, r.Method, r.URL.Path, time.Since(t))
}

func handle(w http.ResponseWriter, r *http.Request) (err error) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Accept, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

	if r.URL.Path == "/upload" {
		return handleCurlUpload(w, r)
	} else if r.URL.Path == "/uploads" {
		// return a list of files
		return handleListUploads(w, r)
	} else if r.URL.Path == "/uploads2" {
		// return a list of files
		return handleListUploadsWithMetadata(w, r)
	} else if strings.HasSuffix(r.URL.Path, "ogg") {
		return handleServeFile(w, r)
	} else if strings.HasSuffix(r.URL.Path, "ogg.json") {
		return handleServeFile(w, r)
	} else if r.URL.Path == "/uploader" {
		return handleBrowserUpload(w, r)
	} else if r.URL.Path == "/" {
		if r.Method == "POST" {
			return handleBrowserUpload(w, r)
		} else {
			return handleServeIndex(w, r, ``)
		}
	} else if strings.HasPrefix(r.URL.Path, "/static/") {
	} else if strings.HasPrefix(r.URL.Path, "/radio_stations.json") {
		var b []byte
		b, err = ioutil.ReadFile("../lib/radio_stations.json")
		if err != nil {
			return
		}
		w.Header().Set("Content-Type", "application/json")
		w.Write(b)
	} else {
		w.Write([]byte("ok"))
	}

	return
}

func handleServeIndex(w http.ResponseWriter, r *http.Request, data string) (err error) {
	indexHTML, err = ioutil.ReadFile("static/index.html")
	if err != nil {
		return
	}
	log.Debugf("serving index with data: %s", data)
	indexHTML = bytes.Replace(indexHTML, []byte("XX"), []byte(data), -1)
	w.Write(indexHTML)
	return
}

func handleServeFile(w http.ResponseWriter, r *http.Request) (err error) {

	fname := strings.TrimPrefix(r.URL.Path, "/")
	_, fname = filepath.Split(fname)
	fname = path.Join(ContentDirectory, fname)

	if strings.HasSuffix(fname, ".ogg.json") {
		fnameOgg := strings.TrimSuffix(fname, ".json")
		if _, err = os.Stat(fnameOgg); err != nil {
			log.Error("no such file")
			return
		}
		if _, err = os.Stat(fname); err != nil {
			// create wavefeorm
			err = ToWaveform(fnameOgg)
			if err != nil {
				log.Error(err)
				return
			}
		}
		w.Header().Set("Content-Type", "application/json")
	}
	f, err := os.Open(fname)
	defer f.Close()
	if err != nil {
		return
	}
	io.Copy(w, f)
	return
}

// curl -F file="@/location/to/file" /upload
func handleCurlUpload(w http.ResponseWriter, r *http.Request) (err error) {
	// Set upload limit
	r.ParseMultipartForm(120 << 20) // 120 Mb
	file, handler, err := r.FormFile("file")
	if err != nil {
		fmt.Fprintf(w, "%s\n", err.Error())
		return
	}
	defer file.Close()
	log.Debugf("Uploaded File: %+v\n", handler.Filename)
	log.Debugf("Content type : %+v\n", handler.Header.Get("Content-Type"))
	log.Debugf("File Size    : %+v\n", handler.Size)
	log.Debugf("MIME Header  : %+v\n", handler.Header)

	tempfile, err := ioutil.TempFile(os.TempDir(), "upload_"+handler.Filename)
	if err != nil {
		fmt.Fprintf(w, "%s\n", err.Error())
		return
	}
	defer tempfile.Close()

	_, err = io.Copy(tempfile, file)
	if err != nil {
		fmt.Fprintf(w, "%s\n", err.Error())
		return
	}

	fname2, err := saveFile(tempfile.Name(), make(map[string]string))
	if err != nil {
		fmt.Fprintf(w, "%s\n", err.Error())
		return
	}

	fmt.Fprintf(w, "uploaded %s\n", fname2)

	return
}

func handleBrowserUpload(w http.ResponseWriter, r *http.Request) (errBig error) {
	returnText := ""
	defer func() {
		if errBig == nil {
			errBig = handleServeIndex(w, r, returnText)
		} else {
			errBig = handleServeIndex(w, r, errBig.Error())
		}
	}()
	dodelete := false
	metadata := make(map[string]string)
	// define some variables used throughout the function
	// n: for keeping track of bytes read and written
	// err: for storing errors that need checking
	var n int
	var err error

	// define pointers for the multipart reader and its parts
	var mr *multipart.Reader
	var part *multipart.Part

	if mr, err = r.MultipartReader(); err != nil {
		errBig = err
		return
	}

	// buffer to be used for reading bytes from files
	chunk := make([]byte, 4096)

	// continue looping through all parts, *multipart.Reader.NextPart() will
	// return an End of File when all parts have been read.
	for {
		// variables used in this loop only
		// tempfile: filehandler for the temporary file
		// filesize: how many bytes where written to the tempfile
		// uploaded: boolean to flip when the end of a part is reached
		var tempfile *os.File
		var filesize int
		var uploaded bool

		if part, err = mr.NextPart(); err != nil {
			if err != io.EOF {
				errBig = err
				return
			}
			return
		}
		tempfile, err = os.Create(path.Join(os.TempDir(), "upload_"+part.FileName()))
		if err != nil {
			errBig = err
			return
		}
		defer os.Remove(tempfile.Name())

		log.Debugf("Temporary filename: %s\n", tempfile.Name())

		// continue reading until the whole file is upload or an error is reached
		for !uploaded {
			if n, err = part.Read(chunk); err != nil {
				if err != io.EOF {
					errBig = err
					return
				}
				uploaded = true
			}

			if n, err = tempfile.Write(chunk[:n]); err != nil {
				errBig = err
				return
			}
			filesize += n
		}
		log.Debugf("Uploaded filesize: %d bytes", filesize)
		tempfile.Close()

		log.Debug("form: ", part.FormName())
		if part.FormName() == "metaband" ||
			part.FormName() == "metaartist" ||
			part.FormName() == "metaotherinfo" {
			bs, err := getFileContents(tempfile.Name())
			if err != nil {
				log.Error(err)
				return
			}
			log.Debugf("meta data: %s -> '%s'", part.FormName(), bs)
			metadata[part.FormName()] = bs
			continue
		} else if part.FormName() == "dodelete" {
			bs, err := getFileContents(tempfile.Name())
			if err != nil {
				log.Error(err)
				return
			}
			dodelete = bs == "on"
			continue
		}

		metadata["metafile"] = part.FileName()
		log.Debugf("Uploaded filename: %s", part.FileName())
		log.Debugf("Uploaded mimetype: %s", part.Header)

		var fname2 string
		doing := "uploaded"
		if dodelete {
			fname2, err = removeFile(tempfile.Name())
			doing = "deleted"
		} else {
			removeFile(tempfile.Name()) // remove file if it exists
			fname2, err = saveFile(tempfile.Name(), metadata)
		}
		if err != nil {
			returnText = returnText + fmt.Sprintf("error on '%s': %s\n", part.FileName(), err.Error())
			log.Debugf("can't save: %s", tempfile.Name())
		} else {
			returnText = returnText + fmt.Sprintf("%s '%s' as '%s'\n", doing, part.FileName(), fname2)
			log.Debugf("%s %s", doing, fname2)
		}
	}
	return
}

func getFileContents(fname string) (s string, err error) {
	b, err := ioutil.ReadFile(fname)
	if err != nil {
		log.Error(err)
		return
	}
	s = string(b)
	return
}

func handleListUploads(w http.ResponseWriter, r *http.Request) (err error) {
	fileList, err := filepath.Glob("uploads/*.ogg")
	// strip prefix
	for i, f := range fileList {
		fileList[i] = filepath.Base(f)
	}
	if err == nil {
		jsonResponse(w, http.StatusOK, map[string][]string{"uploads": fileList})
	}
	return
}

func handleListUploadsWithMetadata(w http.ResponseWriter, r *http.Request) (err error) {
	fileList, err := filepath.Glob("uploads/*.ogg")
	// strip prefix
	var uploads []MetadataInfo
	for i, f := range fileList {
		var fileHash string
		fileList[i] = filepath.Base(f)
		fileHash, err = Filemd5Sum(f)
		if err != nil {
			log.Error(err)
			return
		}
		if _, ok := metadataSaved[fileHash]; !ok {
			// collect metadata
			m, errM := collectMetaData(f)
			if errM == nil {
				metadataSaved[fileHash] = m
			}
		}
		if _, ok := metadataSaved[fileHash]; ok {
			uploads = append(uploads, metadataSaved[fileHash])
		}
	}
	if err == nil {
		jsonResponse(w, http.StatusOK, uploads)
	}
	return
}

func collectMetaData(fname string) (m MetadataInfo, err error) {
	m.File = filepath.Base(fname)

	out, err := exec.Command("ffprobe", "-i", fname, "-show_streams", "-v", "quiet").CombinedOutput()
	if err != nil {
		log.Error("ffprobe error", err)
		log.Errorf("%s", out)
		return
	}
	var r *regexp.Regexp
	var foo []string
	r, _ = regexp.Compile(`TAG:metafile='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.OriginalFile = foo[1]
	}
	r, _ = regexp.Compile(`TAG:metaband='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.Band = foo[1]
	}
	r, _ = regexp.Compile(`TAG:metaartist='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.Artist = foo[1]
	}
	r, _ = regexp.Compile(`TAG:metabpm='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.BPM = foo[1]
	}
	r, _ = regexp.Compile(`TAG:metaotherinfo='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.OtherInfo = foo[1]
	}
	r, _ = regexp.Compile(`TAG:metadate='(.+)'`)
	foo = r.FindStringSubmatch(string(out))
	if len(foo) > 1 {
		m.Date = foo[1]
	}

	return
}

// CopyMax copies only the maxBytes and then returns an error if it
// copies equal to or greater than maxBytes (meaning that it did not
// complete the copy).
func CopyMax(dst io.Writer, src io.Reader, maxBytes int64) (n int64, err error) {
	n, err = io.CopyN(dst, src, maxBytes)
	if err != nil && err != io.EOF {
		return
	}

	if n >= maxBytes {
		err = fmt.Errorf("Upload exceeds maximum size")
	} else {
		err = nil
	}
	return
}

// Filemd5Sum determines the md5 hash of a file
func Filemd5Sum(pathToFile string) (result string, err error) {
	file, err := os.Open(pathToFile)
	if err != nil {
		return
	}
	//Tell the program to call the following function when the current function returns
	defer file.Close()
	//Open a new hash interface to write to
	hash := md5.New()
	//Copy the file in the hash interface and check for any error
	if _, err = io.Copy(hash, file); err != nil {
		return
	}
	//Get the 16 bytes hash
	hashInBytes := hash.Sum(nil)[:16]
	//Convert the bytes to a string
	result = hex.EncodeToString(hashInBytes)
	return
}

func removeFile(tempfname string) (fname2 string, err error) {
	hash, err := Filemd5Sum(tempfname)
	if err != nil {
		return
	}
	fileList, err := filepath.Glob("uploads/*.ogg")
	for _, f := range fileList {
		fname := filepath.Base(f)
		if strings.HasPrefix(fname, hash) {
			fname2 = fname
			err = os.Remove(f)
		}
	}

	if fname2 == "" {
		err = fmt.Errorf("could not find file to delete with hash '%s'", hash)
	}
	return
}

func saveFile(tempfname string, metadata map[string]string) (fname2 string, err error) {
	fname, err := ToOgg(tempfname, metadata)
	if err != nil {
		log.Debugf("error converting: %s", err.Error())
		return
	}

	hash, err := Filemd5Sum(tempfname)
	if err != nil {
		log.Warn(err)
		return
	}

	fname2 = hash + ".ogg"
	err = os.Rename(fname, path.Join(ContentDirectory, fname2))
	if err != nil {
		log.Warn(err)
		return
	}

	log.Debugf("saved %s", fname2)
	return
}

func ToWaveform(fname string) (err error) {
	fnameTemp := RandStringBytesMaskImpr(16) + ".wav"
	defer os.Remove(fnameTemp)
	out, err := exec.Command("ffmpeg", "-y", "-i", fname, fnameTemp).CombinedOutput()
	if err != nil {
		log.Error("ffmpeg error", err)
		log.Errorf("%s", out)
		return
	}
	out, err = exec.Command("ffprobe", "-i", fname, "-show_streams", "-v", "quiet").CombinedOutput()
	if err != nil {
		log.Error("ffprobe error", err)
		log.Errorf("%s", out)
		return
	}
	r, _ := regexp.Compile(`duration=(\d+.\d+)`)
	foo := r.FindStringSubmatch(string(out))
	duration := 0.0
	if len(foo) > 1 {
		duration, _ = strconv.ParseFloat(foo[1], 64)
	}
	pixelsPerSecond := 1.0
	if duration > 0 {
		pixelsPerSecond = math.Floor(800 / duration)
		if pixelsPerSecond == 0 {
			pixelsPerSecond = 1
		}
	}
	out, err = exec.Command("audiowaveform", "-i", fnameTemp, "--output-filename", fname+".json", "--pixels-per-second", fmt.Sprint(pixelsPerSecond), "--bits", "16").CombinedOutput()
	if err != nil {
		log.Error("audiowaveform error", err)
		log.Errorf("%s", out)
	}
	return
}

func ToOgg(fname string, metadata map[string]string) (fname2 string, err error) {
	isMusic := false
	// check if music
	for _, v := range []string{"wav", "ogg", "mp3", "m4a", "flac"} {
		if strings.Contains(fname, v) {
			isMusic = true
		}
	}
	if !isMusic {
		err = fmt.Errorf("%s is not music", fname)
		return
	}

	// try to determine tempo
	out, err := exec.Command("aubio", "tempo", fname).CombinedOutput()
	if err != nil {
		log.Error("could not compute tempo")
		log.Debugf("out: %s", out)
	}
	foo := strings.Fields(string(out))
	if len(foo) > 0 {
		metadata["metabpm"] = foo[0]
	}
	metadata["metadate"] = time.Now().Format(time.RFC3339)

	fname2 = strings.TrimSuffix(fname, filepath.Ext(fname)) + ".ogg"
	cmd := []string{"-y", "-i", fname, "-ar", "48000"}
	for k, v := range metadata {
		cmd = append(cmd, "-metadata")
		cmd = append(cmd, fmt.Sprintf("%s='%s'", k, strings.Replace(v, "'", "", -1)))
	}
	cmd = append(cmd, fname2)
	_, err = exec.Command("ffmpeg", cmd...).CombinedOutput()
	return
}

// jsonResponse writes a JSON response and HTTP code
func jsonResponse(w http.ResponseWriter, code int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	json, err := json.Marshal(data)
	if err != nil {
		log.Error(err)
	}
	log.Debugf("json response: %s", json)
	fmt.Fprintf(w, "%s\n", json)
}

const letterBytes = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
const (
	letterIdxBits = 6                    // 6 bits to represent a letter index
	letterIdxMask = 1<<letterIdxBits - 1 // All 1-bits, as many as letterIdxBits
	letterIdxMax  = 63 / letterIdxBits   // # of letter indices fitting in 63 bits
)

func RandStringBytesMaskImpr(n int) string {
	b := make([]byte, n)
	// A rand.Int63() generates 63 random bits, enough for letterIdxMax letters!
	for i, cache, remain := n-1, rand.Int63(), letterIdxMax; i >= 0; {
		if remain == 0 {
			cache, remain = rand.Int63(), letterIdxMax
		}
		if idx := int(cache & letterIdxMask); idx < len(letterBytes) {
			b[i] = letterBytes[idx]
			i--
		}
		cache >>= letterIdxBits
		remain--
	}

	return string(b)
}
