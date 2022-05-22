import torch
import torchvision.models as models
from torchvision import datasets, transforms
import torchvision
from PIL import Image
import torch.nn as nn
import torch.nn.functional as F
from flask import Flask, json, request
# from bottle import route, run, template, request

api = Flask(__name__)
device = torch.device('cpu')

#the code of the Net class needed to load the model
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()
        self.conv1 = nn.Conv2d(1, 32, 3, 1)
        self.conv2 = nn.Conv2d(32, 64, 3, 1)
        self.dropout1 = nn.Dropout(0.25)
        self.dropout2 = nn.Dropout(0.5)
        self.fc1 = nn.Linear(9216, 128)
        self.fc2 = nn.Linear(128, 10)

    def forward(self, x):
        x = self.conv1(x)
        x = F.relu(x)
        x = self.conv2(x)
        x = F.relu(x)
        x = F.max_pool2d(x, 2)
        x = self.dropout1(x)
        x = torch.flatten(x, 1)
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout2(x)
        x = self.fc2(x)
        output = F.log_softmax(x, dim=1)
        return output

#using form the example mnist code
transform=transforms.Compose([
    transforms.ToTensor(),
    transforms.Normalize((0.1307,), (0.3081,))
    ])

def predict(inputs):
    inputs = inputs.to(device)
    output = model(inputs).data.numpy().argmax()
    return str(output)

# @route('/predict', method='POST') BOTTLE SERVER DOESN'T WORK
@api.route('/predict', methods=['POST'])
def returnResult():
    res = {}
    file = request.files['image']
    if not file:
        res['message'] = 'Error. Cannot find image'
        res['Result'] = 'NA'
    else:
        res['message'] = 'Success'
        image = Image.open(file)
        image = transform(image).unsqueeze(0)
        res['Result'] = predict(image)
    print("Returning result json")
    return json.dumps(res)

#main function begins
#load the saved model from the PVC
print("Welcome to inference part")
model = Net()
model.load_state_dict(torch.load('/mnt/srsmnistmodel.pth'))
model.eval()

#run the server
api.run(host='0.0.0.0', port=8000, debug=True)
# run(host='0.0.0.0', port=5000)        BOTTLE SERVER