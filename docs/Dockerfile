FROM ruby:3.2-alpine

# Install dependencies
RUN apk add --no-cache \
    build-base \
    gcc \
    cmake \
    git \
    tzdata

# Set working directory
WORKDIR /site

# Copy Gemfile
COPY Gemfile* ./

# Install gems
RUN bundle install

# Expose Jekyll default port
EXPOSE 4000

# Default command
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--livereload", "--force_polling"]
