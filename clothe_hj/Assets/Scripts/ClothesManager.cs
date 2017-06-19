using UnityEngine;
using System.Collections;

public class ClothesManager : MonoBehaviour {

    //属性
    float rotSpeedScalar = 3;
    Vector3 touchMoved;
    Vector3 touchRotated;

    //缩放系数
    float distance = 10.0f;
    //左右滑动移动速度
    float xSpeed = 250.0f;
    float ySpeed = 120.0f;
    //缩放限制系数
    float yMinLimit = -20f;
    float yMaxLimit = 80f;
    //摄像头的位置
    float x = 0.0f;
    float y = 0.0f;
    //记录上一次手机触摸位置判断用户是在左放大还是缩小手势
    private Vector2 oldPosition1 ;
    private Vector2 oldPosition2 ;
 


    //[Label("内存池配置")]
    [System.Serializable]
    public struct FabricPath
    {
        public string mainTex;
        public string normalTex;
        public int posY;
    }
    public FabricPath[] fabricPool;

    // Use this for initialization
    void Start () {
        touchMoved = new Vector3(0,0,0);
	}
	
	// Update is called once per frame
	void Update () {

#if UNITY_EDITOR || UNITY_STANDALONE_WIN  

        //鼠标操作
        if (Input.GetMouseButton(0))
        {
            //拖动时速度
            //鼠标或手指在该帧移动的距离*deltaTime为手指移动的速度,此处为Input.GetAxis("Mouse X") / Time.deltaTime
            //不通帧率下lerp的第三个参数(即混合比例)也应根据帧率而不同--
            //考虑每秒2帧和每秒100帧的情况，如果此参数为固定值，那么在2帧的情况下，一秒后达到目标速度的0.75,而100帧的情况下，一秒后则基本约等于目标速度
            //currentSpeed = Mathf.Lerp(currentSpeed, Input.GetAxis("Mouse X") / Time.deltaTime, 0.5f * Time.deltaTime);
            touchRotated.y = -Input.GetAxis("Mouse X") * rotSpeedScalar;

            touchMoved.y -= Input.GetAxis("Mouse Y") * 0.05f;
            Camera.main.transform.localPosition = new Vector3(Camera.main.transform.localPosition.x, touchMoved.y, Camera.main.transform.localPosition.z);
        }

        if (Input.GetAxis("Mouse ScrollWheel") < 0)
        {
            if (Camera.main.fieldOfView <= 100)
                Camera.main.fieldOfView += 2;
            if (Camera.main.orthographicSize <= 20)
                Camera.main.orthographicSize += 0.5F;
        }
        //Zoom in  
        if (Input.GetAxis("Mouse ScrollWheel") > 0)
        {
            if (Camera.main.fieldOfView > 2)
                Camera.main.fieldOfView -= 2;
            if (Camera.main.orthographicSize >= 1)
                Camera.main.orthographicSize -= 0.5F;
        }
#else

        //判断触摸数量为单点触摸
	    if(Input.touchCount == 1)
	    {
		    //触摸类型为移动触摸
		    if(Input.GetTouch(0).phase==TouchPhase.Moved)
		    {
		        //根据触摸点计算X与Y位置
			    //x += Input.GetAxis("Mouse X") * xSpeed * 0.02;
       // 	    y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02;
                
                touchRotated.y = -Input.GetAxis("Mouse X") * rotSpeedScalar;
                touchMoved.y -= Input.GetAxis("Mouse Y") * 0.05f;
                
                Camera.main.transform.localPosition = new Vector3(Camera.main.transform.localPosition.x, touchMoved.y, Camera.main.transform.localPosition.z);
		    }
	    }

        //判断触摸数量为多点触摸
        if (Input.touchCount > 1)
        {
            //前两只手指触摸类型都为移动触摸
            if (Input.GetTouch(0).phase == TouchPhase.Moved || Input.GetTouch(1).phase == TouchPhase.Moved)
            {
                //计算出当前两点触摸点的位置
                var tempPosition1 = Input.GetTouch(0).position;
                var tempPosition2 = Input.GetTouch(1).position;
                //函数返回真为放大，返回假为缩小
                if (isEnlarge(oldPosition1, oldPosition2, tempPosition1, tempPosition2))
                {
                    //放大系数超过3以后不允许继续放大
                    //这里的数据是根据我项目中的模型而调节的，大家可以自己任意修改
                    if (distance > 3)
                    {
                        if (Camera.main.fieldOfView > 2)
                            Camera.main.fieldOfView -= 0.5f;
                        if (Camera.main.orthographicSize >= 1)
                            Camera.main.orthographicSize -= 0.3F;
                    }
                }
                else
                {
                    //缩小洗漱返回18.5后不允许继续缩小
                    //这里的数据是根据我项目中的模型而调节的，大家可以自己任意修改
                    if (distance < 18.5)
                    {
                        if (Camera.main.fieldOfView <= 100)
                            Camera.main.fieldOfView += 0.5f;
                        if (Camera.main.orthographicSize <= 20)
                            Camera.main.orthographicSize += 0.3F;
                    }
                }
                //备份上一次触摸点的位置，用于对比
                oldPosition1 = tempPosition1;
                oldPosition2 = tempPosition2;
            }
        }

#endif



        gameObject.transform.Rotate(touchRotated);

	}

    bool isEnlarge(Vector2 oP1, Vector2 oP2 , Vector2 nP1, Vector2 nP2)
    {
	    //函数传入上一次触摸两点的位置与本次触摸两点的位置计算出用户的手势
        var leng1 = Mathf.Sqrt((oP1.x - oP2.x) * (oP1.x - oP2.x) + (oP1.y - oP2.y) * (oP1.y - oP2.y));
        var leng2 = Mathf.Sqrt((nP1.x - nP2.x) * (nP1.x - nP2.x) + (nP1.y - nP2.y) * (nP1.y - nP2.y));
        if(leng1<leng2)
        {
    	     //放大手势
             return true;
        }else
        {
    	    //缩小手势
            return false;
        }
    }

    void OnGUI()
    {
        foreach(FabricPath fp in fabricPool)
        {
            DrawButton(fp);
        }

        //if (GUI.Button(new Rect(650, 20, 200, 20), "是否使用法线图"))
        //{

        //}

        //if (GUI.Button(new Rect(650, 70, 200, 20), "是否使用AO图"))
        //{

        //}
    }

    void DrawButton(FabricPath fp)
    {
        string dir = GetDirName(fp.mainTex);
        if (GUI.Button(new Rect(100, fp.posY, 250, 40), dir))
        {
            GameObject xiuzi2 = gameObject.transform.Find("xifu/xifuxiuzi2/default_MeshPart0").gameObject;
            if (xiuzi2)
            {
                ReplaceTex(xiuzi2, fp);
            }
            GameObject xiuzi21 = gameObject.transform.Find("xifu/xifuxiuzi2/default_MeshPart1").gameObject;
            if (xiuzi21)
            {
                ReplaceTex(xiuzi21, fp);
            }
            GameObject xiuzi22 = gameObject.transform.Find("xifu/xifuxiuzi2/default_MeshPart2").gameObject;
            if (xiuzi22)
            {
                ReplaceTex(xiuzi22, fp);
            }

            GameObject xifudashenR = gameObject.transform.Find("xifu/xifudashen-R/default007_MeshPart0").gameObject;
            if (xifudashenR)
            {
                ReplaceTex(xifudashenR, fp);
            }
            GameObject xifudashenR1 = gameObject.transform.Find("xifu/xifudashen-R/default007_MeshPart1").gameObject;
            if (xifudashenR1)
            {
                ReplaceTex(xifudashenR1, fp);
            }

            GameObject xifudashenL = gameObject.transform.Find("xifu/xifudashen-L/default001_MeshPart0").gameObject;
            if (xifudashenL)
            {
                ReplaceTex(xifudashenL, fp);
            }
            GameObject xifudashenL1 = gameObject.transform.Find("xifu/xifudashen-L/default001_MeshPart1").gameObject;
            if (xifudashenL1)
            {
                ReplaceTex(xifudashenL1, fp);
            }

            GameObject xifulingzi = gameObject.transform.Find("xifu/xifulingzi").gameObject;
            if (xifulingzi)
            {
                ReplaceTex(xifulingzi, fp);
            }

            GameObject xiongdai = gameObject.transform.Find("xifu/xiongdai").gameObject;
            if (xiongdai)
            {
                ReplaceTex(xiongdai, fp);
            }

            GameObject xiakoudaiL = gameObject.transform.Find("xifu/xiakoudai-L").gameObject;
            if (xiakoudaiL)
            {
                ReplaceTex(xiakoudaiL, fp);
            }

            GameObject xiakoudaiR = gameObject.transform.Find("xifu/xiakoudai-R").gameObject;
            if (xiakoudaiR)
            {
                ReplaceTex(xiakoudaiR, fp);
            }
        }
    }

    void ReplaceTex(GameObject go, FabricPath fp)
    {
        Texture2D MainTex = Resources.Load<Texture2D>(fp.mainTex);
        Texture2D BumpMap = Resources.Load<Texture2D>(fp.normalTex);

        Material mat = go.GetComponent<Renderer>().material;
        mat.SetTexture("_MainTex", MainTex);
        mat.SetTexture("_BumpMap", BumpMap);
    }

    static string GetDirName(string path)
    {
       string[] strs = path.Split('/');
       return strs[1];
    }

    static string GetFileName(string path)
    {
        string[] strs = path.Split('/');
        return strs[2];
    }
    
}
