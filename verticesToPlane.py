""" verticesToPlane.py
-Usage:
    This script creates a window on loading
    The interface has three buttons:
    --- "set plane"
        Expects for three vertices to be selected,
        these vertices will define the plane other vertices will snap to.
        Creates annotations to mark the selected vertices
    --- "move vertices"
        Moves the selected vertices to the plane defined by the "set plane" button
    --- "clear"
        Removes annotations created by the "set plane" button
Tested on: maya 2016 trial version
Made by: Rokas Rakauskas
"""

import maya.cmds as mc
import math

class Vector(object):
    """Vector class with the basic vector math operations
    """

    def __init__(self, input=[0,0,0]):
        """Takes an [x,y,z] list as an input
        Raises error if input is the wrong length or non number values
        """
        if len(input) == 3:
            self.x = input[0]
            self.y = input[1]
            self.z = input[2]
        else:
            raise ValueError("Expected list of length 3 , got length %d" % len(input))

    @property
    def x(self):
        """x component getter
        """
        return self._x

    @property
    def y(self):
        """y component getter
        """
        return self._y

    @property
    def z(self):
        """z component getter
        """
        return self._z

    @x.setter
    def x(self, value):
        """x component setter
        """
        check = self.checkForFloat(value)
        self._x = check

    @y.setter
    def y(self, value):
        """y component setter
        """
        check = self.checkForFloat(value)
        self._y = check

    @z.setter
    def z(self, value):
        """z component setter
        """
        check = self.checkForFloat(value)
        self._z = check

    def checkForFloat(self, value):
        """Takes in a value, if input is int or float returns it as a float
        raises error otherwise"""
        out = value
        if type(value) == int:
            out= float(value)
        if type(out) == float:
            return out
        else:
            raise TypeError("expected a number got %r" % (type(value)) )

    def length(self):
        """Returns the length of this vector"""
        return math.sqrt((self.x*self.x) + (self.y*self.y) + (self.z*self.z))

    def lengthNonZero(self):
        """Returns False if length is zero, True if this Vector has a direction
        """
        if abs(self.length()) < 0.00000000000001: #floating point zero
            return False
        else:
            return True

    def normalize(self):
        """Change the length of this vector to 1
        Raises error if length is zero
        """
        if self.lengthNonZero():
            length = self.length()
            self.x = self.x/length
            self.y = self.y/length
            self.z = self.z/length
        else:
            raise ValueError("zero length vector, did not normalize")

    def dot(self, input):
        """Takes a Vector input, returns a scalar dot product
        """
        if type(input) != Vector:
            raise TypeError("expected Vector type got %r" % (type(input)) )
        return (self.x*input.x) + (self.y*input.y) + (self.z*input.z)

    def cross(self, input):
        """Takes a Vector input, returns Vector cross product
        """
        if type(input) != Vector:
            raise TypeError("expected Vector type got %r" % (type(input)) )
        x = (self.y*input.z) - (self.z*input.y)
        y = (self.z*input.x) - (self.x*input.z)
        z = (self.x*input.y) - (self.y*input.x)
        return Vector([x, y, z])

    def __add__(self, input):
        """Overwrite for the + operator, takes in a Vector, returns a Vector sum
        """
        if type(input) != Vector:
            raise TypeError("expected Vector type got %r" % (type(input)) )
        x = self.x + input.x
        y = self.y + input.y
        z = self.z + input.z
        return Vector([x, y, z])

    def __sub__(self, input):
        """Overwrite for the - operator, takes in a Vector, returns a Vector difference
        """
        if type(input) != Vector:
            raise TypeError("expected Vector type got %r" % (type(input)) )
        x = self.x - input.x
        y = self.y - input.y
        z = self.z - input.z
        return Vector([x, y, z])

    def scale(self, input):
        """Takes a scalar, returns the product of input and this vector
        """
        check = self.checkForFloat(input)
        x = self.x*check
        y = self.y*check
        z = self.z*check
        return Vector([x, y, z])

    def asList(self):
        """Returns this vector as a list [x, y, z]
        """
        return([self.x, self.y, self.z])

class verticesToPlane():
    """main class for snapping vertices to plane
    UI shows on instantiation
    """
    def __init__(self):
        """Initializes the plane, shows window
        """

        #initialize the plane we'll be snapping to
        self.planePosition = Vector([0,0,0])
        self.planeNormal = Vector([0,0,0])
        #names of the annotations we'll be using to mark the plane selection
        self.annotationName = "annotateVtx"
        self.layerName = "annotateLayer"

        #UI
        winName = "verticesToPlane"
        width = 200
        height = 70
        #clean up previous
        if mc.window(winName, exists=True):
            mc.deleteUI(winName)
        self.clear()
        winName = mc.window(winName,title="flatten", widthHeight=(width, height), sizeable=False)
        mc.columnLayout()
        mc.button("set plane", command=self.setPlane, width=width)
        mc.button("move vertices",command=self.snapVertices, width=width)
        mc.button("clear", command=self.clear, width=width)
        mc.setParent("..")
        mc.showWindow(winName)

    def clear(self, *args):
        """Removes annotations, "clear" button command
        """
        if mc.objExists(self.layerName) and mc.objectType(self.layerName) ==  "displayLayer":
            members = mc.editDisplayLayerMembers(self.layerName, query=True)
            mc.delete(members)
            mc.delete(self.layerName)

    def snapVertices(self, *args):
        """Moves vertices to the plane defined by planePosition and planeNormal
        "move vertices" button command
        """
        if self.planeNormal.lengthNonZero():
            sel = mc.ls(selection=True, flatten=True)

            #move vertices along the planeNormal to snap to plane
            for vtx in sel:
                pos = Vector(mc.pointPosition(vtx, world=True))

                #vector from the plane position to the current vertex
                vct1 = self.planePosition - pos

                #distance from vertex to the plane along the planeNormal
                delta = self.planeNormal.dot(vct1)
                moveVector = self.planeNormal.scale(delta)
                mc.xform(vtx, translation=moveVector.asList(), relative=True)
        else:
            mc.confirmDialog(message="please define the plane first")

    def setPlane(self, *args):
        """Sets planePostion and planeNormal from three selected vertices
        "set plane" button command
        """
        sel = mc.ls(selection=True, flatten=True)
        if len(sel) == 3 and mc.selectType(vertex=True, query=True):

            #vertices position vectors
            points = [Vector(mc.pointPosition(i, world=True)) for i in sel]

            #vectors along triangle edge
            v1 = points[1] - points[0]
            v2 = points[2] - points[0]

            #plane is defined as position of the first vertex and
            #the normal from the cross product of the edge vectors
            self.planePosition = points[0]
            self.planeNormal = v1.cross(v2)
            self.planeNormal.normalize()

            #create the annotations
            self.clear()
            layer = mc.createDisplayLayer(name=self.layerName, empty=True)
            for i, point in enumerate(points):
                annotation = mc.annotate(sel[i],text="V%d" % i, point=point.asList())
                annTrans = mc.listRelatives(annotation, parent=1)
                mc.editDisplayLayerMembers(layer, annotation)
                mc.editDisplayLayerMembers(layer, annTrans)
                mc.setAttr("%s.displayType" % layer, 2)

            #return selection
            selParent = mc.listRelatives(sel[0], parent=True)
            mc.hilite(selParent, replace=True)
            mc.selectType(vertex=True, objectComponent=True)
        else:
            mc.confirmDialog(message="please select exactly three vertices")

    def __del__(self):
        """Remove annotations when closing
        """
        self.clear()

verticesToPlane()
