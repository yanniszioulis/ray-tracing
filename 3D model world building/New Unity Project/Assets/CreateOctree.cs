using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class CreateOctree : MonoBehaviour
{
    public GameObject[] worldObjects;
    public int nodeMinSize = 1; 
    Octree otree;
    void Start()
    {
        otree = new Octree(worldObjects, nodeMinSize);
        using (StreamWriter writer = new StreamWriter("OctreeInfo.txt")){
            otree.rootNode.TraverseAndWrite(writer);
        }
    }

    void OnDrawGizmos(){
        if(Application.isPlaying){
            otree.rootNode.Draw();
        }
    }
}
