# Todo List

## Setup
Using Surrealist Desktop, start serving a local database at `localhost:8000`. Create a namespace within called `TodoList` and a database within that called `TodoList`. Add a user for the database with username `user` and password `password`.

Then, go to the server directory and run `go run server.go`, you should get the following output:
```
Setting up databse...
Loading env file...
Establishing connection to database... source: 
ws://localhost:8000
Signing into database...
Sign in complete!
Database setup complete!
2025/03/26 08:32:34 connect to http://localhost:8080/ for GraphQL playground
```

Then, you can run the client frontend using Android Studio (or by going to the client directory and running `flutter run`)