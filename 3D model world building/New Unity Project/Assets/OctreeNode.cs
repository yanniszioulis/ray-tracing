using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO; 

public class OctreeNode
{
    Bounds nodeBounds; 
    float minSize;
    Bounds[] childBounds;
    public OctreeNode[] children = null;
    public Material materialID;
    public bool mid1 = false;
    public bool dividing = false;

    public OctreeNode(Bounds b, float minNodeSize){
        nodeBounds = b;
        minSize = minNodeSize;

        float quarter = nodeBounds.size.y/4.0f;
        float childLength = nodeBounds.size.y/2;
        Vector3 childSize = new Vector3(childLength, childLength, childLength);
        childBounds = new Bounds[8];
        childBounds[0] = new Bounds(nodeBounds.center + new Vector3(-quarter, quarter, -quarter), childSize);
        childBounds[1] = new Bounds(nodeBounds.center + new Vector3(quarter, quarter, -quarter), childSize);
        childBounds[2] = new Bounds(nodeBounds.center + new Vector3(-quarter, quarter, quarter), childSize);
        childBounds[3] = new Bounds(nodeBounds.center + new Vector3(quarter, quarter, quarter), childSize);
        childBounds[4] = new Bounds(nodeBounds.center + new Vector3(-quarter, -quarter, -quarter), childSize);
        childBounds[5] = new Bounds(nodeBounds.center + new Vector3(quarter, -quarter, -quarter), childSize); 
        childBounds[6] = new Bounds(nodeBounds.center + new Vector3(-quarter, -quarter, quarter), childSize);
        childBounds[7] = new Bounds(nodeBounds.center + new Vector3(quarter, -quarter, quarter), childSize);

    }

    public void AddObject(GameObject go){
        DivideAndAdd(go);
    }

    public void DivideAndAdd(GameObject go){
        if(nodeBounds.size.y <= minSize || IsFullyEncapsulated(go.GetComponent<Collider>().bounds)){
            // set material ID here since it will be a leaf node 
            if(nodeBounds.Intersects(go.GetComponent<Collider>().bounds)){
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
                children[i] = new OctreeNode(childBounds[i], minSize);
            }
            if(childBounds[i].Intersects(go.GetComponent<Collider>().bounds)){
                dividing = true;
                children[i].DivideAndAdd(go);
            }
        }
        if(!dividing){
            children = null;
        }
    }

    private bool IsFullyEncapsulated(Bounds colliderBounds){
        foreach (Vector3 corner in GetCorners()){
            if (!colliderBounds.Contains(corner)){
                return false;
            }
        }
        return true;
    }

    private Vector3[] GetCorners(){
        Vector3[] corners = new Vector3[8];
        corners[0] = nodeBounds.min;
        corners[1] = new Vector3(nodeBounds.min.x, nodeBounds.min.y, nodeBounds.max.z);
        corners[2] = new Vector3(nodeBounds.min.x, nodeBounds.max.y, nodeBounds.min.z);
        corners[3] = new Vector3(nodeBounds.min.x, nodeBounds.max.y, nodeBounds.max.z);
        corners[4] = new Vector3(nodeBounds.max.x, nodeBounds.min.y, nodeBounds.min.z);
        corners[5] = new Vector3(nodeBounds.max.x, nodeBounds.min.y, nodeBounds.max.z);
        corners[6] = new Vector3(nodeBounds.max.x, nodeBounds.max.y, nodeBounds.min.z);
        corners[7] = nodeBounds.max;
        return corners;
    }

    public void TraverseAndWrite(StreamWriter writer, int depth = 0){
        string indent = new string(' ', depth * 2);
        writer.WriteLine($"{indent}Node Bounds: {nodeBounds}");
        writer.WriteLine($"{indent}Material ID: {(materialID != null ? materialID.name : "None")}");
        writer.WriteLine($"{indent}Mid1: {mid1}");
        writer.WriteLine($"{indent}Dividing: {dividing}");
        if (children != null){
            for (int i = 0; i < 8; i++){
                if (children[i] != null){
                    children[i].TraverseAndWrite(writer, depth + 1);
                }
            }
        }
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
