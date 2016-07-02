# SurviveAmsterdam-backend

## Swift backend demo with Perfect.
This project it is a simply demo to show how to deploy a
REST API services using [Perfect](https://www.perfect.org) on Heroku. What is it Perfect?

 _Perfect is a web server and toolkit for developers using the Swift programming language to build applications and other REST services._

Starting from this Perfect [example](https://github.com/PerfectlySoft/Perfect-Heroku-Buildpack-Example) I decided to create very basic REST services for a my side project [SurviveAmsterdam](https://github.com/darthpelo/SurviveAmsterdam), to show you how is possible to create Backend and Mobile using only `Swift`.

The first scope of this REST APIs is very simple:
* Save Product information to the DB, only `String` properties
* Retrieve all the Products saved by a specific user
* Retrieve all the Products saved on the DB

## Disclaimer
1) I am not a backend developer, my tech background are iOS, hardware and firmware, so feel free to give me suggestions or create pull request

2) Due to the purpose of this project, I don't made any dumb of the SQLite DB before any deploy

## To Do list
- [ ] Save images on AWS S3
- [ ] Save DB before any deploys
