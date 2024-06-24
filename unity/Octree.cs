using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class Octree
{
    public OctreeNode rootNode;
    private int index = 1; // Initialize index to track node positions
    private int world_bit_depth = 10;
    
    public Octree(GameObject[] worldObjects, float minNodeSize){
        if (worldObjects == null || worldObjects.Length == 0){
            throw new System.ArgumentException("worldObjects array cannot be null or empty");
        }

        float centerValue = ((Mathf.Pow(2, world_bit_depth) - 1) / 2);
        float extentValue = Mathf.Pow(2, world_bit_depth);

        Vector3 center = new Vector3(centerValue, centerValue, centerValue);
        Vector3 extents = new Vector3(extentValue, extentValue, extentValue);

        // Initialize bounds with the calculated center and extents
        Bounds bounds = new Bounds(center, extents);

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