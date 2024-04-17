import argparse
import cv2
import glob
import os
import shutil
import torch
import torch_neuronx

from basicsr.archs.rrdbnet_arch import RRDBNet

model = RRDBNet(num_in_ch=1, num_out_ch=1, scale=2, num_feat=64, num_block=23, num_grow_ch=32)
model.eval()

example = torch.rand(1024,768)

trace = torch_neuronx.trace(model, example)
