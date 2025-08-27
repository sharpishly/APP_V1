# Base image
FROM php:8.2-fpm

# Set working directory to match volume mount and Nginx root
WORKDIR /var/www/app/sharpishly.com

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libonig-dev \
    libzip-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-install pdo pdo_mysql zip mbstring \
    && rm -rf /var/lib/apt/lists/*

# Optional: install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy application files to the container (overridden by mounted volumes)
COPY . /var/www/app/sharpishly.com

# Set proper permissions
RUN chown -R www-data:www-data /var/www/app/sharpishly.com \
    && chmod -R 755 /var/www/app/sharpishly.com

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
