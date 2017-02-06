#include <metal_stdlib>

using namespace metal;

struct VertexOut
{
    float4  position [[position]];
//    float4  color;
    float2  st;
};

struct VertexIn
{
    packed_float3 position;
    packed_float2 st;
};

/**
 * 1、所有的vertex shaders必须以关键字vertex开头。函数必须至少返回顶点的最终位置——你通过指定float4（一个元素为4个浮点数的向量）。然后你给一个名字给vetex shader，以后你将用这个名字来访问这个vertex shader。
 * 2、vertex shader会接受一个名叫vertex_id的属性的特定参数，它意味着它会被vertex数组里特定的顶点所装入。
 * 3、一个指向一个元素为packed_float4(一个向量包含4个浮点数)的数组的指针，如：每个顶点的位置。这个 [[ ... ]] 语法被用在声明那些能被用作特定额外信息的属性，像是资源位置，shader输入，内建变量。这里你把这个参数用 [[ buffer(0) ]] 标记，来指明这个参数将会被在你代码中你发送到你的vertex shader的第一块buffer data所遍历。
 * 4、基于vertex id来检索vertex数组中对应位置的vertex并把它返回。向量必须为一个float4类型 
 */
vertex VertexOut passThroughVertex(uint vid [[ vertex_id ]],
                                     const device VertexIn* vertex_array [[ buffer(0) ]])
// ,constant packed_float4* color    [[ buffer(1) ]]
{
    VertexOut outVertex;
    VertexIn VertexIn = vertex_array[vid];
    outVertex.position = float4(VertexIn.position,1);
    outVertex.st = VertexIn.st;
//    outVertex.color    = color[vid];
    
    return outVertex;
};


fragment float4 passThroughFragment1(VertexOut frag [[stage_in]], texture2d<float> texas[[texture(0)]]) {  //1
    constexpr sampler defaultSampler;
    float4 rgba = texas.sample(defaultSampler, frag.st).rgba;
    return rgba;
}





/**
 * 1. 所有fragment shaders必须以fragment关键字开始。这个函数必须至少返回fragment的最终颜色——你通过指定half4（一个颜色的RGBA值）来完成这个任务。注意，half4比float4在内存上更有效率，因为，你写入了更少的GPU内存。
 * 2. 这里你返回颜色
 */
//fragment half4 passThroughFragment(VertexOut inFrag [[stage_in]])
//{
//    return half4(inFrag.color);
//};
