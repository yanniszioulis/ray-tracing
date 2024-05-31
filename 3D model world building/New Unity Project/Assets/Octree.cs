using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Octree
{
    public OctreeNode rootNode;
    
    public Octree(GameObject[] worldObjects, float minNodeSize){
        if (worldObjects == null || worldObjects.Length == 0){
            throw new System.ArgumentException("worldObjects array cannot be null or empty");
        }

        // Initialize bounds with the first object's collider bounds
        Bounds bounds = new Bounds(worldObjects[0].GetComponent<Collider>().bounds.center, Vector3.zero);

        foreach(GameObject go in worldObjects){
            bounds.Encapsulate(go.GetComponent<Collider>().bounds);
        }

        float maxSize = Mathf.Max(new float[] {bounds.size.x, bounds.size.y, bounds.size.z});
        maxSize = Mathf.Pow(2, Mathf.Ceil(Mathf.Log(maxSize, 2)));
        Vector3 sizeVector = new Vector3(maxSize, maxSize, maxSize) * 0.5f;
        bounds.SetMinMax(bounds.center - sizeVector, bounds.center + sizeVector);
        rootNode = new OctreeNode(bounds, minNodeSize);
        AddObjects(worldObjects);
    }

    public void AddObjects(GameObject[] worldObjects){
        foreach(GameObject go in worldObjects){
            rootNode.AddObject(go);
        }
    }
}
