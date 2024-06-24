using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO; 

public class OctreeNode
{
    public Bounds nodeBounds; 
    public float minSize;
    public Bounds[] childBounds;
    public OctreeNode[] children = null;
    public Material materialID;
    public bool mid1 = false;
    public bool dividing = false;
    public int nodeIndex; // Node index to track the position

    public OctreeNode(Bounds b, float minNodeSize, int index){
        nodeBounds = b;
        minSize = minNodeSize;
        nodeIndex = index;

        float quarter = nodeBounds.size.y/4.0f;
        float childLength = nodeBounds.size.y/2.0f;
        Vector3 childSize = new Vector3(childLength, childLength, childLength);
        childBounds = new Bounds[8];
        childBounds[0] = new Bounds(nodeBounds.center + new Vector3(-quarter, -quarter, -quarter), childSize);
        childBounds[1] = new Bounds(nodeBounds.center + new Vector3(-quarter, -quarter, quarter), childSize);
        childBounds[2] = new Bounds(nodeBounds.center + new Vector3(-quarter, quarter, -quarter), childSize);
        childBounds[3] = new Bounds(nodeBounds.center + new Vector3(-quarter, quarter, quarter), childSize);
        childBounds[4] = new Bounds(nodeBounds.center + new Vector3(quarter, -quarter, -quarter), childSize);
        childBounds[5] = new Bounds(nodeBounds.center + new Vector3(quarter, -quarter, quarter), childSize); 
        childBounds[6] = new Bounds(nodeBounds.center + new Vector3(quarter, quarter, -quarter), childSize);
        childBounds[7] = new Bounds(nodeBounds.center + new Vector3(quarter, quarter, quarter), childSize);
    }

    public void AddObject(GameObject go, ref int index){
        DivideAndAdd(go, ref index);
    }

    public void DivideAndAdd(GameObject go, ref int index){
        Bounds goBounds = go.GetComponent<Collider>().bounds;
        Vector3 rgoSize = goBounds.size;
        Bounds rgoBounds = new Bounds(goBounds.center, rgoSize*2);
        if(nodeBounds.size.y <= minSize || IsFullyEncapsulated(rgoBounds)){
            // set material ID here since it will be a leaf node 
            if(nodeBounds.Intersects(goBounds)){
                materialID = go.GetComponent<Renderer>().material;
                // if this is null, we will set a bool to true to assign it a default material 
                // during parsing 
                if(materialID==null){
                    mid1 = true; 
                }
                // the only other time materialID should be null is when 
                // it is intersecting NOTHING (air)
            }
            return;
        }
        if(children == null){
            children = new OctreeNode[8];
        }
        
        for(int i = 0; i < 8; i++){
            if(children[i] == null){
                children[i] = new OctreeNode(childBounds[i], minSize, index++);
            }
            Bounds checkInner = new Bounds(goBounds.center, goBounds.size - new Vector3(0.001f, 0.001f, 0.001f));
            if(childBounds[i].Intersects(goBounds) && childBounds[i].Intersects(checkInner)){ 
                dividing = true;
                children[i].DivideAndAdd(go, ref index);
            }
        }
        if(!dividing){
            children = null;
        }
    }

    private bool IsFullyEncapsulated(Bounds colliderBounds){
        return colliderBounds.Contains(nodeBounds.min) && colliderBounds.Contains(nodeBounds.max);
    }
    private Vector3 RoundSize(Vector3 bsize){
        float RoundCoord(float value){
            return Mathf.Round(value / minSize) * minSize;
        }

        return new Vector3(
            RoundCoord(bsize.x),
            RoundCoord(bsize.y),
            RoundCoord(bsize.z)
        );
    }

    public void Draw(){
        Gizmos.color = new Color(0, 1, 0);
        Gizmos.DrawWireCube(nodeBounds.center, nodeBounds.size);
        if(children != null){
            for(int i = 0; i < 8; i++){
                if(children[i] != null){
                    children[i].Draw();
                }
            }
        }
    }
}