from datetime import datetime
import os
from flask import Flask, request, jsonify, render_template_string
import uuid
import openai
from dotenv import load_dotenv
import requests
import boto3
from template import HTML_TEMPLATE


# Load environment variables
load_dotenv()

# Initialize Flask
app = Flask(__name__)

# Configure services
openai.api_key = os.getenv("OPENAI_API_KEY")
UNSPLASH_API_KEY = os.getenv("UNSPLASH_API_KEY")
BUCKET_NAME = os.getenv("AWS_BUCKET_NAME")

# Configure AWS S3
s3 = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('AWS_SECRET_KEY')
)

@app.route("/", defaults={"religion": "Jewish"})
@app.route("/<religion>")
def greeting_card(religion):
    try:
        current_date = datetime.now().strftime("%d.%m.%Y")
        
        # Updated to use the correct method for chat-based models
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",  # Specify the model version
            messages=[{
                "role": "user", 
                "content": f"Create a short greeting card for a real holiday occurring today {current_date} in the context of the {religion} religion or culture. Include a title and a brief message."
            }],
            max_tokens=100,
            temperature=0.7
        )
        
        result = response['choices'][0]['message']['content'].strip()  # Access the result in the new format
        
        try:
            title, content = result.split("\n", 1)
            title = title.replace("Title: ", "").strip()
            content = content.replace("Message: ", "").strip()
        except ValueError:
            title = result
            content = ""
        
        try:
            # Searching for image on Unsplash
            unsplash_response = requests.get(
                "https://api.unsplash.com/search/photos",
                params={"client_id": UNSPLASH_API_KEY, "query": title},
                timeout=3
            ).json()
            image_url = unsplash_response["results"][0]["urls"]["small"]
        except:
            image_url = "https://via.placeholder.com/150"
        
        # Return the result with HTML_TEMPLATE
        return render_template_string(HTML_TEMPLATE, title=title, content=content, image_url=image_url)
    except Exception as e:
        return str(e), 500

@app.route('/share', methods=['POST'])
def share():
    try:
        data = request.json
        html_content = render_template_string(HTML_TEMPLATE, **data)
        file_name = f"card-{uuid.uuid4()}.html"
        
        # Save the HTML file to S3
        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=file_name,
            Body=html_content,
            ContentType='text/html'
        )
        
        # Return the URL of the saved file
        return jsonify({"url": f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/health_check", methods=["GET"])
def health_check():
    return jsonify({"status": "healthy"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
