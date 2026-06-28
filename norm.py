import math

x = [-0.06472814, -0.06788221, -0.14946738]
y = [0.16309169, -0.044890985, -0.050240546]
z = [-0.018697111, -0.15657279, 0.07920612]

def normalize(v):
    mag = math.sqrt(sum(c*c for c in v))
    return [c/mag for c in v]

nx = normalize(x)
ny = normalize(y)
nz = normalize(z)

print(f"Transform3D({nx[0]:.7f}, {ny[0]:.7f}, {nz[0]:.7f}, {nx[1]:.7f}, {ny[1]:.7f}, {nz[1]:.7f}, {nx[2]:.7f}, {ny[2]:.7f}, {nz[2]:.7f}, -0.149857, -0.031822, 0.117868)")
