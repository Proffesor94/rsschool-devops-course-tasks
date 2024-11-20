# Use an official Go runtime as a parent image with version 1.23
FROM golang:1.23 AS builder

# Set the working directory in the container
WORKDIR /app

# Clone the word-cloud-generator repository && # Build the application
RUN git clone https://github.com/wickett/word-cloud-generator.git . && \
    go build -o word-cloud-generator .

# Create a lightweight Docker image for production
FROM alpine:3.20
RUN apk add --no-cache gcompat

# Copy the binary from the builder stage
COPY --from=builder /app/word-cloud-generator /usr/local/bin/word-cloud-generator

# Expose the default port
EXPOSE 8888

# Run the application
CMD ["/usr/local/bin/word-cloud-generator"]

# Push the image to ECR (manual trigger)
FROM alpine:3.20 as ecr_push

ARG REPOSITORY_URI
ARG VERSION

RUN echo $REPOSITORY_URI:$VERSION > /dev/null

# Build and push the Docker image
RUN docker build -t ${REPOSITORY_URI}:${VERSION} . && \
    docker push ${REPOSITORY_URI}:${VERSION}
