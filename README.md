# Procedural Lighting Tool (Bachelor Thesis)

A procedural tool developed in Houdini using Python and VEX that automatically generates area lights from LiDAR scans and HDRI data.  
The tool analyzes LiDAR-based geometry, extracts local orientation, computes light dimensions, bakes texture projections, and constructs production-ready lights with correct transforms.

---

##Demo Video
[![Light Rig Demo](thumbnail.png)](https://vimeo.com/1144911549?share=copy&fl=sv&fe=ci)

## Summary of How It Works
The tool:
-Projects the HDRI onto the LiDAR geometry
-finds the light sources based on a luminance threshold defined by the artist
-deletes all geometry from the LiDAR geometry, that is not part of the light sources
-creates Grid Geometries that represent Area Lights
-Extracts a 3x3 transform matrix, converts it into Euler rotations and computes the lights dimentions from the bounding boxes
-renders automatically extracted emisson maps from the projected texture using COPs
-Creates light nodes with assigned baked textures

<details>
<summary><strong>Show code snippet</strong></summary>

```python
# Get the matrix from the point attribute
pt = xform_geo.iterPoints()[0]
matrix_vals = pt.attribValue("transform")  # 9 floats
matrix3 = hou.Matrix3(matrix_vals)

R = matrix_vals
R00, R01, R02 = R[0], R[1], R[2]
R10, R11, R12 = R[3], R[4], R[5]
R20, R21, R22 = R[6], R[7], R[8]

if abs(R20) != 1:
    pitch = -math.asin(R20)
    cos_pitch = math.cos(pitch)
    roll = math.atan2(R21 / cos_pitch, R22 / cos_pitch)
    yaw = math.atan2(R10 / cos_pitch, R00 / cos_pitch)
else:
    yaw = 0
    if R20 == -1:
        pitch = math.pi / 2
        roll = yaw + math.atan2(R01, R02)
    else:
        pitch = -math.pi / 2
        roll = -yaw + math.atan2(-R01, -R02)

euler_deg = [math.degrees(a) for a in (roll, pitch, yaw)]

    

# Get bounding box and center
bbox = grid_geo.boundingBox()
center = bbox.center()
size_x = bbox.sizevec()[0]
size_y = bbox.sizevec()[1]
# Get all point positions
points = grid_geo.points()
# Calculate vectors along local axes
# Typical grid point order: bottom-left, bottom-right, top-right, top-left
p0 = points[0].position()
p1 = points[1].position()
p2 = points[2].position()
p3 = points[3].position()


x_vec = p1 - p0  # Local X axis
y_vec = p2 - p0  # Local Y axis

size_x = x_vec.length()
size_y = y_vec.length()




#render textures
rot_x = euler_deg[0]
if abs(rot_x) > 90:
    flip.bypass(False)
    

toCopsNode.cook(force=True)
cop_node.cook(force=True)

rop.parm("copoutput").set(texture_path)

rop.render()

flip.bypass(True)

if iteration == 0:
    env_texture_path = f"{version_path}/Environment.exr"
    rop_env.parm("copoutput").set(env_texture_path)
    rop_env.render()
    




# Create the area light
light = hou.node("/obj").createNode("custom_light", light_name)
light.parm("light_type").set(2)
light.parmTuple("position_vector").set(center)
light.parm("distance_mult").set(1)
light.parmTuple("rotate").set(euler_deg)
light.parm("area_sizex").set(size_x)
light.parm("area_sizey").set(size_y)
light.parm("light_intensity").set(1.0)
light.parm("light_enable").set(True)

#set textures
light.parm("light_texture").set(texture_path)

