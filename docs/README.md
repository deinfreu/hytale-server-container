# Documentation Site

This directory contains the Jekyll-based documentation site for the Hytale Server Container project.

## Local Development

### Option 1: Docker (Recommended)

**Prerequisites:** Docker and Docker Compose

1. Start the development server:
   ```bash
   cd docs
   docker-compose up
   ```

2. Open your browser to `http://localhost:4000/hytale-server-container/`

3. Stop the server with `Ctrl+C` or:
   ```bash
   docker-compose down
   ```

**Available Docker Commands:**
- `docker-compose up` - Start server with live reload
- `docker-compose up --build` - Rebuild and start server
- `docker-compose down` - Stop and remove containers
- `docker-compose exec jekyll bundle exec jekyll build` - Build site
- `docker-compose exec jekyll bundle exec jekyll clean` - Clean build artifacts

**Testing Production Build:**
```bash
docker-compose run -e JEKYLL_ENV=production jekyll bundle exec jekyll serve --host 0.0.0.0
```

### Option 2: Native Ruby

**Prerequisites:** Ruby 2.7+ (3.0+ recommended) and Bundler

1. Install dependencies:
   ```bash
   cd docs
   bundle install
   ```

2. Start the development server:
   ```bash
   bundle exec jekyll serve
   ```

3. Open your browser to `http://localhost:4000/hytale-server-container/`

**Available Commands:**
- `bundle exec jekyll serve --livereload` - Start with live reload
- `bundle exec jekyll build` - Build the site
- `bundle exec jekyll clean` - Clean build artifacts
- `JEKYLL_ENV=production bundle exec jekyll serve` - Production build

## Theme

The site uses the [Just the Docs](https://just-the-docs.com/) theme with custom color schemes based on Tailwind CSS Slate colors.

### Available Color Schemes

- `dark` - Default dark theme
- `slate_light` - Custom light theme (Tailwind Slate)
- `slate_dark` - Custom dark theme (Tailwind Slate)

To change the color scheme, edit `_config.yml`:

```yaml
color_scheme: slate_light  # or slate_dark, dark
```

## Structure

```
docs/
├── _config.yml           # Jekyll configuration
├── _includes/            # Custom includes and components
├── _layouts/             # Custom layouts
├── _sass/                # Custom styles
│   └── custom/
│       ├── custom.scss   # Main custom styles
│       └── color_schemes/
│           ├── slate_light.scss
│           └── slate_dark.scss
├── guide/                # User guides
├── installation/         # Installation docs
└── technical/            # Technical documentation
```
