# Task Manager Spring Boot API

Requires Java 17+ and Maven 3.6.3+.

## Run locally

```bash
cd backend
mvn spring-boot:run
```

The default development database is an H2 file under `backend/data`. The API runs at
`http://localhost:8080/api`.

## PostgreSQL

Set these environment variables before starting:

```bash
export DB_URL=jdbc:postgresql://localhost:5432/taskmanager
export DB_USERNAME=taskmanager
export DB_PASSWORD=change-me
mvn spring-boot:run
```

Endpoints:

- `GET /api/health`
- `POST /api/auth`
- `GET /api/tasks?email=user@example.com`
- `PUT /api/tasks/{uuid}`
- `GET /api/planner?email=...&weekStart=...` returns one Sunday–Saturday workspace.
- `PUT /api/planner/{uuid}` saves a note, event, or checklist activity.
- `DELETE /api/planner/{uuid}?email=...` removes a planner block.

## Amazon S3 object storage

The bucket defaults to `taskmanager-user-files-durgasiva` in `ap-southeast-2`.
The API uses the AWS SDK default credential chain; credentials are never stored in
the repository or returned to the iOS app.

For local development, configure a newly generated key with `aws configure`, then run:

```bash
export AWS_REGION=ap-southeast-2
export S3_BUCKET=taskmanager-user-files-durgasiva
mvn spring-boot:run
```

- `POST /api/storage/upload-url` creates a 10-minute private upload URL.
- `POST /api/storage/download-url` creates a 10-minute private download URL.
- `PUT /api/storage/profile-image` saves an uploaded object as the user's profile photo.
- `GET /api/storage/profile-image-url?email=...` returns a private profile-photo URL.

Allowed uploads are JPEG, PNG, HEIC, and PDF. Keep S3 Block Public Access enabled.
