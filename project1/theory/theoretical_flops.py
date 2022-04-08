import torch
from pthflops import count_ops
from torchvision.models import resnet18, resnet34, resnet50

models = [resnet18, resnet34, resnet50]

device = torch.device('cuda')
inp = torch.rand(1,3,224,224).to(device)

for model in models:
    print(model)
    print("****************")
    model = model().to(device)
    count_ops(model, inp)
    print("\nxxxxxxxxxxxxxxx\n")
