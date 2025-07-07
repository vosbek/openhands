from flask import Flask
import datetime

app = Flask(__name__)

@app.route('/')
def get_time():
    return str(datetime.datetime.now())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
