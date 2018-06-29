
// 4、创建一个Vertex Shader
// 一个vertex shader被每个顶点调用，它的工作是接受顶点的信息（如：位置和颜色、纹理坐标），返回一个潜在的修正位置（可能还有别的相关信息）
// 添加头文件。
#include <metal_stdlib>
using namespace metal;

/**
 * 1、所有的vertex shaders必须以关键字vertex开头。函数必须至少返回顶点的最终位置——你通过指定float4（一个元素为4个浮点数的向量）。然后你给一个名字给vetex shader，以后你将用这个名字来访问这个vertex shader。
 * 2、vertex shader会接受一个名叫vertex_id的属性的特定参数，它意味着它会被vertex数组里特定的顶点所装入。
 * 3、一个指向一个元素为packed_float4(一个向量包含4个浮点数)的数组的指针，如：每个顶点的位置。这个 [[ ... ]] 语法被用在声明那些能被用作特定额外信息的属性，像是资源位置，shader输入，内建变量。这里你把这个参数用 [[ buffer(0) ]] 标记，来指明这个参数将会被在你代码中你发送到你的vertex shader的第一块buffer data所遍历。
 * 4、基于vertex id来检索vertex数组中对应位置的vertex并把它返回。向量必须为一个float4类型
 */

/*
vertex float4 basic_vertex (
    constant packed_float3* vertex_array[[buffer(0)]],
                            unsigned int vid[[vertex_id]]){
    return float4(vertex_array[vid], 1.0);

}
*/
// 5、创建一个Fragment Shader
/*
 1. 所有fragment shaders必须以fragment关键字开始。这个函数必须至少返回fragment的最终颜色——你通过指定half4（一个颜色的RGBA值）来完成这个任务。注意，half4比float4在内存上更有效率，因为，你写入了更少的GPU内存。
 2. 这里返回(0.6,0.6,0.6,0.6)的颜色，也就是灰色。
 */

/*
fragment half4 basic_fragment() {
    return half4(0.6);
}
*/

// 输入的顶点和纹理坐标
struct VertexIn
{
    packed_float3 position;
    packed_float2 st;
};

// 输出顶点和纹理坐标，因为需要渲染纹理，可以不用输入顶点颜色
struct VertexOut
{
    float4 position [[position]];
    float4 color;
    float2 st;
};

// 添加颜色
struct VertextInOut
{
    // 我们必须区分 (通过使用 [[position]] 属性) 哪一个结构体成员应该被看做是顶点位置:
    float4 position [[position]];
    float4 color;
    float2 st;
};

/**
 *  顶点函数
 *  @param vid 索引，用来告诉函数当前操作的是哪个顶点
 *  @param position   顶点函数在顶点数据中每个顶点被执行一次。它接收顶点列表的一个指针
 *
 *  @return outVertex
 */
vertex VertextInOut basic_vertex(uint vid[[vertex_id]], constant packed_float3* position[[buffer(0)]], constant packed_float4* color [[buffer(1)]])
{
    VertextInOut outVertex;
    outVertex.position = float4(position[vid], 1.0);
    outVertex.color = color[vid];
    return outVertex;
};

fragment half4 basic_fragment(VertextInOut inFrag[[stage_in]])
{
    return half4(inFrag.color);
};


// 添加纹理顶点坐标
vertex VertexOut texture_vertex(uint vid[[vertex_id]], const device VertexIn *vertex_array[[buffer(0)]])
{
    VertexOut outVertex;
    VertexIn vertexIn = vertex_array[vid];
    outVertex.position = float4(vertexIn.position, 1.0);
    outVertex.st = vertexIn.st;
//    outVertex.color = color[vid];
    return outVertex;
};


fragment float4 texture_fragment(VertextInOut inFrag[[stage_in]], texture2d<float> texas[[texture(0)]])
{
    constexpr sampler defaultSampler;
    float4 rgba = texas.sample(defaultSampler, inFrag.st).rgba;
    return rgba;
};


