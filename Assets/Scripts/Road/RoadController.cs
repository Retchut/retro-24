using Unity.VisualScripting;
using UnityEngine;

public class RoadController : MonoBehaviour
{
    private void OnTriggerEnter(Collider other)
    {
        if (other.gameObject.CompareTag("Destroy"))
        {
            // Destroy the GameObject this script is attached to
            Destroy(gameObject);
        }
    }
}
