HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Greeting Card</title>
    <style>
        .top-left {
            position: absolute;
            top: 20px;
            left: 20px;
        }
        .religion-list {
            list-style: none;
            padding: 0;
            margin: 0;
            background: #fff;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        .religion-list li {
            padding: 10px 15px;
            border-bottom: 1px solid #eee;
        }
        .religion-list li:last-child {
            border-bottom: none;
        }
        .religion-list a {
            color: #333;
            text-decoration: none;
        }
        .card {
            background: linear-gradient(135deg, #f8b500, #ff5252);
            box-shadow: 0 4px 30px rgba(0,0,0,0.2);
            border-radius: 15px;
            text-align: center;
            padding: 40px 20px;
            width: 80%;
            max-width: 600px;
            margin: 100px auto;
            color: #fff;
        }
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            min-height: 100vh;
            background: linear-gradient(135deg, #ee5522, #ffb347);
        }
        h1 {
            margin-bottom: 20px;
            font-size: 2em;
        }
        p {
            line-height: 1.6;
            margin-bottom: 20px;
        }
        img {
            border-radius: 50%;
            width: 150px;
            height: 150px;
            object-fit: cover;
            margin: 20px 0;
            box-shadow: 0 4px 15px rgba(0,0,0,0.2);
        }
        button {
            background: #f8b500;
            border-radius: 20px;
            padding: 10px 40px;
            font-size: 1.1em;
            color: #fff;
            border: none;
            cursor: pointer;
            transition: background 0.3s;
        }
        button:hover {
            background: #e6a300;
        }
    </style>
</head>
<body>
    <div class="top-left">
        <ul class="religion-list">
            <li><a href="/Judaism">Judaism</a></li>
            <li><a href="/Christianity">Christianity</a></li>
            <li><a href="/Islam">Islam</a></li>
        </ul>
    </div>
    <div class="card">
        <h1 id="titleInput">{{ title }}</h1>
        <p id="contentInput">{{ content }}</p>
        <div><img id="imageInput" src="{{ image_url }}" alt="Holiday image"></div>
        <button id="shareButton">Share</button>
    </div>
    <script>
        document.getElementById('shareButton').addEventListener('click', async () => {
            try {
                const response = await fetch('/share', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        title: document.getElementById('titleInput').textContent,
                        content: document.getElementById('contentInput').textContent,
                        image_url: document.getElementById('imageInput').src
                    })
                });
                
                if (!response.ok) throw new Error('Share failed');
                
                const data = await response.json();
                alert(`Shareable link: ${data.url}`);
            } catch (error) {
                alert('Error sharing: ' + error.message);
            }
        });
    </script>
</body>
</html>
"""