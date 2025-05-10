# Start from the official Go image
FROM golang:1.19-alpine AS builder

# Set working directory
WORKDIR /app

# Install required system dependencies
RUN apk add --no-cache git gcc musl-dev

# Copy go.mod and go.sum files first for better caching
COPY go.mod go.sum ./

# Download dependencies
RUN go mod download

# Copy the rest of the server code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -o todo-server .

# Create a minimal production image
FROM alpine:3.16

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates tzdata

# Set working directory
WORKDIR /app

# Copy the binary from the builder stage
COPY --from=builder /app/todo-server /app/todo-server

# Set necessary environment variables
ENV GIN_MODE=release
ENV PORT=8080

# Expose the application port
EXPOSE 8080

# Run the application
CMD ["/app/todo-server"] 