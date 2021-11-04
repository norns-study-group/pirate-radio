barebones simple upload / display server. 

allows anyone to upload any wav file. (if you try to upload something else it will delete it).

uploaded wav files are converted to flac and stored.


## getting started

[install Go](https://golang.org/dl/).

now to run:

```
go run main.go
```

and it will open a webserver on `localhost:8730`.

you can upload files with:

```
curl -F file="@somefile.wav" localhost:8730/upload
```

you can get a list of uploads:

```
curl localhost:8730/uploads
```

you can download a particular upload:

```
curl localhost:8730/48925d458fc6ff202b1c2e4767c385f7.ogg
```

you can view all the uploads and listen to them at `localhost:8730` in the browser.