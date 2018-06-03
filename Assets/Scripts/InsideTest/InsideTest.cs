using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InsideTest : MonoBehaviour {

    public Transform point;
    private Plane plane;

	// Use this for initialization
	void Start () {
        
	}
	
	// Update is called once per frame
	void Update () {
        plane = new Plane( GetComponent<MeshFilter>().mesh.normals[0], transform.position);

        
       // Debug.Log(IsPointBehindPlane());

    }

    bool IsPointBehindPlane()
    {
        return plane.GetSide(point.position);
    }
}
