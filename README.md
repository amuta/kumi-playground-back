# Kumi API

Rails 8 API backend with kumi-parser for code compilation.

## Requirements

- Docker or Ruby 3.3.8

## Docker Setup

### Build

```bash
docker build -t kumi-api \
  --build-arg VITE_API_BASE=http://localhost:3000 \
  .
```

### Run

```bash
docker run -p 3000:3000 \
  -e WEB_ORIGIN="*" \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -v $(pwd)/db:/rails/db \
  kumi-api
```

Available at `http://localhost:3000`

### Environment Variables

- `WEB_ORIGIN` - CORS origins (default: `*`)
- `SECRET_KEY_BASE` - Rails secret key
- `VITE_API_BASE` - Frontend API endpoint (build-time)

## Local Development

### Setup

```bash
bundle install
bin/rails db:setup
```

### Run

```bash
bin/rails server
```

### Tests

```bash
bundle exec rspec
```