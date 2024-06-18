using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class Octree
{
    public OctreeNode rootNode;
    private int index = 1; // Initialize index to track node positions
    
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
        rootNode = new OctreeNode(bounds, minNodeSize, 0);
        AddObjects(worldObjects);
    }

    public void AddObjects(GameObject[] worldObjects){
        foreach(GameObject go in worldObjects){
            rootNode.AddObject(go, ref index);
        }
    }

    public void BreadthFirstTraversal(string filePath){
        Queue<OctreeNode> queue = new Queue<OctreeNode>();
        List<string> outputLines = new List<string>();
        
        queue.Enqueue(rootNode);

        while(queue.Count > 0){
            OctreeNode currentNode = queue.Dequeue();

            string materialIDInfo = currentNode.materialID != null ? currentNode.materialID.name : "None";
            string nodeInfo = $"Node {currentNode.nodeIndex}: Material ID = {materialIDInfo}, MID1 = {currentNode.mid1}";
            // Debugging print: 
            // string nodeInfo = $"Node {currentNode.nodeIndex}: Bounds Center = {currentNode.nodeBounds.center}, Size = {currentNode.nodeBounds.size}, Material ID = {materialIDInfo}, MID1 = {currentNode.mid1}";
            
            if(currentNode.children != null){
                for(int i = 0; i < 8; i++){
                    if(currentNode.children[i] != null){
                        queue.Enqueue(currentNode.children[i]);
                        if(i == 0){ // Print first child index
                            nodeInfo += $", First Child Index = {currentNode.children[i].nodeIndex}";
                        }
                    }
                }
            }
            outputLines.Add(nodeInfo);
        }

        File.WriteAllLines(filePath, outputLines);
    }
}