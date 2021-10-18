barebones simple upload / display server. 

allows anyone to upload any wav file. (if you try to upload something else it will delete it).

uploaded wav files are converted to flac and stored.


## getting started

[install Go](https://golang.org/dl/).

now to run:

```
go run main.go
```

and it will open a webserver on `localhost:8098`.

you can upload files with:

```
curl --upload-file somewav.wav localhost:8098
```

you can get a list of uploads:

```
curl localhost:8098/uploads
```

you can download a particular upload:

```
curl localhost:8098/48925d458fc6ff202b1c2e4767c385f7.flac
```

you can view all the uploads and listen to them at `localhost:8098` in the browser.