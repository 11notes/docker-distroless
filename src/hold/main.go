package main

import (
	"os"
	"os/signal"
	"syscall"
)

func main(){
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, os.Interrupt, syscall.SIGTERM, syscall.SIGSTOP, syscall.SIGINT)
	<-signalChannel
	os.Exit(1)
}