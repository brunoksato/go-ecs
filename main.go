package main

import (
	"context"
	"os"
	"os/signal"
	"time"

	"github.com/brunoksato/go-ecs/api"
	"github.com/brunoksato/go-ecs/config"
	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

func boot() {
	config.Init()
	api.RW_DB_POOL = config.InitDB()
	api.RW_DB_POOL.LogMode(true)
}

func SetupRouter(test bool) *echo.Echo {
	e := echo.New()
	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// Route => handler
	e.GET("/", api.Home)

	private := e.Group("/api")
	private.GET("/test", api.Test)

	return e
}

func main() {
	boot()

	// Echo instance
	root := SetupRouter(false)

	// Start serve./configure --enable-pythoninterpr
	addr := ":" + os.Getenv("PORT")
	go func() {
		if err := root.Start(addr); err != nil {
			root.Logger.Info("shutting down the server")
		}
	}()

	quit := make(chan os.Signal)
	signal.Notify(quit, os.Interrupt)
	<-quit
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := root.Shutdown(ctx); err != nil {
		root.Logger.Fatal(err)
	}
}
