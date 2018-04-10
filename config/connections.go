package config

import (
	"fmt"
	"os"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres"
)

var CONFIGURATIONS map[string]string = map[string]string{
	"DB":   "host=dev.c7srmclzep5h.us-east-1.rds.amazonaws.com user=petmondo dbname=petmondo password=wedevelop1352100 sslmode=disable",
	"NAME": "PETMONDO",
	"PORT": "8080",
}

func Init() {
	if os.Getenv("NAME") == "" {
		os.Setenv("NAME", CONFIGURATIONS["NAME"])
	}
	if os.Getenv("PORT") == "" {
		os.Setenv("PORT", CONFIGURATIONS["PORT"])
	}
}

func InitDB() *gorm.DB {
	if os.Getenv("DB") == "" {
		os.Setenv("DB", CONFIGURATIONS["DB"])
	}

	db, err := gorm.Open("postgres", os.Getenv("DB"))
	if err != nil {
		panic(err.Error())
	}

	fmt.Println("Initialized read-write database connection pool")

	return db
}