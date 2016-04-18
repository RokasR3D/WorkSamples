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

import pymel.core as pm

class flattenWin():
    """Class that creates the window
    """
    def __init__ (self):
        # initialise class variables
        self.winTitle = "flattenVertices"
        if pm.uitypes.Window.exists(self.winTitle):
            pm.windows.deleteUI(self.winTitle)
        self.normal = pm.datatypes.Vector([0,0,0])
        self.position = pm.datatypes.Vector([0,0,0])
        self.annoName = "annotateVtx"
        self.layername = "annotateLayer"
        self.cleanUp()

        #UI
        win = pm.window(self.winTitle)
        layout = pm.columnLayout()
        btnWidth = 200
        setBtn = pm.button( label="set plane", parent=layout, width=btnWidth)
        moveBtn = pm.button( label="move vertices", parent=layout, width=btnWidth)
        cleanBtn = pm.button(label="reset", parent=layout, width=btnWidth)
        setBtn.setCommand(self.setButtonPress)
        moveBtn.setCommand(self.moveButtonPress)
        cleanBtn.setCommand(self.cleanUp)
        win.show()
        pm.scriptJob(uiDeleted=[self.winTitle, self.cleanUp])

    def cleanUp(self, *args):
        """Removes annotations
        Called by "reset" button
        """
        if pm.objExists(self.layername):
            layerObj = pm.PyNode(self.layername)
            if layerObj.type() ==  "displayLayer":
                members = layerObj.listMembers()
                pm.delete(members)
                pm.delete(layerObj)

    def setButtonPress(self, *args):
        """Sets the plane we'll be snapping to from the three selected vertices
        Called by "set plane" button
        """
        sel = pm.ls(selection=1, flatten=1)
        if len(sel) ==3:
            self.cleanUp()
            pos1 = sel[0].getPosition()
            pos2 = sel[1].getPosition()
            pos3 = sel[2].getPosition()

            vct1 = pos2-pos1
            vct2 = pos3-pos1
            # ^ is owerwritten to perform a cross product
            self.normal = vct1 ^ vct2
            self.normal.normalize()
            self.position = pos1
            pm.select(sel)

            layerObj = pm.createDisplayLayer(name=self.layername, empty=1)
            for i, vtx  in enumerate(sel):
                annotation = pm.annotate(vtx, tx="V%d" % (i+1), p=vtx.getPosition(space="world") )
                annotation.setAttr("overrideEnabled", 1)
                annotation.setAttr("overrideColor", 17)
                annTrans = annotation.getParent()
                annTrans.rename("annotateVts%d" % (i+1))
                layerObj.addMembers(annTrans)
                layerObj.addMembers(annotation)
            layerObj.setAttr("displayType", 1)
        else:
            pm.confirmDialog(message="Please select exactly 3 vertices", title="Error", button="OK",
                             defaultButton="OK", dismissString="OK", cancelButton="OK")

    def moveButtonPress(self, *args):
        """Moves the selected vertices to the plane defined by
        Called by "move vertices" button
        """
        if self.normal.length > 0:
            sel = pm.ls(sl=1, fl=1)
            #move vertices along the normal to snap to plane
            for vtx in sel:
                pos = vtx.getPosition()
                #vector from the plane position to the current vertex
                vct1 = self.position-pos
                delta = vct1 * self.normal
                vtx.setPosition(pos+(delta * self.normal))
flattenWin()