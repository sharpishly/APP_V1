<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sharpishly</title>
    <!-- Use Tailwind CSS for responsive styling -->
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Apply a simple, clean font to the entire body */
        body {
            font-family: 'Inter', sans-serif;
            background-color: #f3f4f6; /* Light gray background */
        }
    </style>
</head>
<body class="min-h-screen flex flex-col font-sans">

    <!-- Header Section -->
    <header class="bg-indigo-600 text-white p-4 shadow-lg">
        <div class="container mx-auto flex justify-between items-center">
            <h1 class="text-2xl font-bold">Sharpishly</h1>
            <nav>
                <ul class="flex space-x-4">
                    <li><a href="#" class="hover:text-indigo-200 transition-colors">Home</a></li>
                    <li><a href="#" class="hover:text-indigo-200 transition-colors">About</a></li>
                    <li><a href="#" class="hover:text-indigo-200 transition-colors">Contact</a></li>
                </ul>
            </nav>
        </div>
    </header>

    <!-- Main Content Section -->
    <main class="flex-grow container mx-auto p-4 md:p-8">
        <!-- Introduction Section -->
        <section class="bg-white rounded-lg shadow-md p-6 mb-8">
            <h2 class="text-3xl font-semibold text-gray-800 mb-4">Upgrading to v0.1</h2>
            <p class="text-gray-600 leading-relaxed">
                <a href="#">Site is undergoing an upgrade to version 0.1 Have a sneak peak here</a>
            </p>
        </section>

        <!-- Two-Column Layout Section (becomes one column on mobile) -->
        <section class="grid md:grid-cols-2 gap-8">
            <!-- Left Column -->
            <div class="bg-white rounded-lg shadow-md p-6">
                <h3 class="text-xl font-semibold text-gray-800 mb-2">Software Development</h3>
                <p class="text-gray-600 leading-relaxed">
                    Sharpishly goal is to make AI accessible to everyone.
                </p>
            </div>
            

        </section>
    </main>

    <!-- Footer Section -->
    <footer class="bg-gray-800 text-white p-4 mt-8">
        <div class="container mx-auto text-center text-sm">
            &copy; 2024 Sharpishly. All rights reserved.
        </div>
    </footer>

</body>
</html>
