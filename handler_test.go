package main

import "github.com/labstack/echo"

func Router() *echo.Echo {
	return SetupRouter(true)
}
