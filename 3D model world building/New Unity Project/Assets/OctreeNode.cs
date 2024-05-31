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
        Bounds goBounds = go.GetComponent<Collider>().bounds;
        Vector3 rgoSize = RoundSize(goBounds.size);
        Bounds rgoBounds = new Bounds(goBounds.center, rgoSize);
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
                children[i] = new OctreeNode(childBounds[i], minSize);
            }
            Bounds checkOuter = new Bounds(goBounds.center, goBounds.size - new Vector3(0.001f, 0.001f, 0.001f));
            if(childBounds[i].Intersects(goBounds) && childBounds[i].Intersects(checkOuter)){ 
                dividing = true;
                children[i].DivideAndAdd(go);
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
        float Round(float value){
            return Mathf.Round(value / minSize) * minSize;
        }

        return new Vector3(
            Round(bsize.x),
            Round(bsize.y),
            Round(bsize.z)
        );
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
