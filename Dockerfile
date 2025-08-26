FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libonig-dev \
    libzip-dev \
    unzip \
    git \
    curl \
    default-mysql-client \
    && docker-php-ext-install pdo_mysql mbstring zip \
    && rm -rf /var/lib/apt/lists/*

# Optional: install Composer globally
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy application files (overridden by mounted volumes anyway)
COPY . /var/www/app

# Set proper permissions
RUN chown -R www-data:www-data /var/www/app \
    && chmod -R 755 /var/www/app

# Expose PHP-FPM port
EXPOSE 9000

# Start PHP-FPM
CMD ["php-fpm"]
