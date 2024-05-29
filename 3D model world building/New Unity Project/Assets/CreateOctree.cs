using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateOctree : MonoBehaviour
{
    public GameObject[] worldObjects;
    public int nodeMinSize = 1; 
    Octree otree;
    void Start()
    {
        otree = new Octree(worldObjects, nodeMinSize);
    }

    void OnDrawGizmos(){
        if(Application.isPlaying){
            otree.rootNode.Draw();
        }
    }
}
