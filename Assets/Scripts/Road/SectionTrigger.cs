using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SectionTrigger : MonoBehaviour
{
    public GameObject[] roadSections; // Array of prefabs to choose from
    private float sectionSpacing = 40f; // Spacing of terrain
    private float originalZ = 0f;

    void Start()
    {
        // buscar transforme da primeira tile
        originalZ = GameObject.Find("First_Road_Section").transform.position.z - (sectionSpacing / 2);
    }

    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("Trigger"))
        {
            // Check if there are road sections to choose from
            if (roadSections.Length > 0)
            {
                // Calculate the new z position based on the number of instantiated sections
                float newZ = other.transform.parent.gameObject.transform.position.z + sectionSpacing * 2;

                // Randomly select a prefab from the array
                int randomIndex = Random.Range(0, roadSections.Length);
                GameObject selectedRoadSection = roadSections[randomIndex];

                // Instantiate the selected prefab with the new position
                Instantiate(selectedRoadSection, new Vector3(0, 0, newZ), Quaternion.identity);
            }
            else
            {
                Debug.LogWarning("No road sections available.");
            }
        }
    }
}
