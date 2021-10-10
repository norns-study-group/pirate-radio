package main

import (
	"bufio"
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/schollz/logger"
	log "github.com/schollz/logger"
)

const MaxBytesPerFile = 100000000 // 100 MB
const ContentDirectory = "uploads"

func main() {
	port := 8730
	os.MkdirAll(ContentDirectory, 0644)
	log.SetLevel("debug")
	log.Infof("listening on :%d", port)
	http.HandleFunc("/", handler)
	http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
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

	if r.Method == "PUT" {
		// handle curl
		return handlePutUpload(w, r)
	} else if r.URL.Path == "/uploads" {
		// return a list of files
		return handleListUploads(w, r)
	} else if strings.HasSuffix(r.URL.Path, "flac") {
		return handleGetUpload(w, r)
	} else {
		b, _ := ioutil.ReadFile("static/index.html")
		w.Write(b)
	}

	return
}

func handleGetUpload(w http.ResponseWriter, r *http.Request) (err error) {
	fname := strings.TrimPrefix(r.URL.Path, "/")
	_, fname = filepath.Split(fname)
	fname = path.Join(ContentDirectory, fname)
	log.Debug(fname)
	f, err := os.Open(fname)
	if err != nil {
		return
	}
	io.Copy(w, f)
	return
}

func handleListUploads(w http.ResponseWriter, r *http.Request) (err error) {
	fileList, err := filepath.Glob("uploads/*.flac")
	// strip prefix
	for i, f := range fileList {
		fileList[i] = strings.TrimPrefix(f, "uploads/")
	}
	if err == nil {
		jsonResponse(w, http.StatusOK, map[string][]string{"uploads": fileList})
	}
	return
}

func handlePutUpload(w http.ResponseWriter, r *http.Request) (err error) {
	f, err := os.CreateTemp("", "*.wav")
	if err != nil {
		log.Error(err)
		return
	}
	// remove temp file when finished
	defer os.Remove(f.Name())

	// try to write the bytes
	n, err := CopyMax(f, r.Body, MaxBytesPerFile)
	f.Close()

	// if an error occured, then erase the temp file
	if err != nil {
		os.Remove(f.Name())
		log.Error(err)
		return
	} else {
		log.Debugf("wrote %d bytes to %s", n, f.Name())
	}

	fname2, err := ToFlac(f.Name())
	if err != nil {
		log.Debugf("error converting to flac: %s", err.Error())
		os.Remove(fname2)
		return
	}

	log.Debug(fname2)

	hash, err := Filemd5Sum(fname2)
	if err != nil {
		log.Warn(err)
		return
	}
	err = os.Rename(fname2, path.Join(ContentDirectory, hash+".flac"))
	log.Debugf("uploaded %s.flac", hash)

	fmt.Fprintf(w, "%s.flac\n", hash)
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
	defer file.Close()
	hash := md5.New()
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		hash.Write(scanner.Bytes())
	}
	result = hex.EncodeToString(hash.Sum(nil))
	return
}

func ToFlac(fname string) (fname2 string, err error) {
	fname2 = strings.TrimSuffix(fname, filepath.Ext(fname)) + ".flac"
	cmd := fmt.Sprintf("-y -i %s -ar 48000 %s",
		fname,
		fname2,
	)
	logger.Debug(cmd)
	_, err = exec.Command("ffmpeg", strings.Fields(cmd)...).CombinedOutput()
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
