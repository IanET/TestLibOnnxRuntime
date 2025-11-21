using LibOnnxRuntime
import .GC: @preserve

const MODEL_PATH = "model.onnx"
const INPUT_NAME = "x"
const OUTPUT_NAME = "y"

GetApi(base, version) = (@ccall $(base.GetApi)(version::UInt32)::Ptr{OrtApi}) |> unsafe_load
CreateEnv(ort, level, status, env) = @ccall $(ort.CreateEnv)(level::Cint, status::Cstring, env::Ptr{Ptr{OrtEnv}})::OrtStatusPtr
GetErrorMessage(ort, status) = (@ccall $(ort.GetErrorMessage)(status::OrtStatusPtr)::Cstring) |> unsafe_string
GetErrorCode(ort, status) = @ccall $(ort.GetErrorCode)(status::OrtStatusPtr)::Cint
CreateSessionOptions(ort, options) = @ccall $(ort.CreateSessionOptions)(options::Ptr{Ptr{OrtSessionOptions}})::OrtStatusPtr
CreateSession(ort, env, model_path, options, session) = @ccall $(ort.CreateSession)(env::Ptr{OrtEnv}, model_path::Cwstring, options::Ptr{OrtSessionOptions}, session::Ptr{Ptr{OrtSession}})::OrtStatusPtr
GetAllocatorWithDefaultOptions(ort, allocator) = @ccall $(ort.GetAllocatorWithDefaultOptions)(allocator::Ptr{Ptr{OrtAllocator}})::OrtStatusPtr
Run(ort, session, run_options, input_names, input_values, input_count, output_names, output_count, output_values) = @ccall $(ort.Run)(session::Ptr{OrtSession}, run_options::Ptr{OrtRunOptions}, input_names::Ptr{Ptr{Cstring}}, input_values::Ptr{Ptr{OrtValue}}, input_count::Csize_t, output_names::Ptr{Ptr{Cstring}}, output_count::Csize_t, output_values::Ptr{Ptr{OrtValue}})::OrtStatusPtr
CreateCpuMemoryInfo(ort, type, mem_type, out) = @ccall $(ort.CreateCpuMemoryInfo)(type::OrtAllocatorType, mem_type::OrtMemType, out::Ptr{Ptr{OrtMemoryInfo}})::OrtStatusPtr
CreateTensorWithDataAsOrtValue(ort, info, p_data, p_data_len, shape, shape_len, type, out) = @ccall $(ort.CreateTensorWithDataAsOrtValue)(info::Ptr{OrtMemoryInfo}, p_data::Ptr{Cvoid}, p_data_len::Csize_t, shape::Ptr{Clonglong}, shape_len::Csize_t, type::ONNXTensorElementDataType, out::Ptr{Ptr{OrtValue}})::OrtStatusPtr

function check_status(ort, status)
    if status != OrtStatusPtr(0)
        msg = GetErrorMessage(ort, status)
        code = GetErrorCode(ort, status)
        println("Status: $code $msg")
    end
end

base = OrtGetApiBase() |> unsafe_load
ort = GetApi(base, ORT_API_VERSION)
env = Ptr{OrtEnv}() |> Ref
status = CreateEnv(ort, ORT_LOGGING_LEVEL_VERBOSE, "Test", env)
check_status(ort, status)
@info "CreateEnv" status env[]

options = Ptr{OrtSessionOptions}() |> Ref
status = CreateSessionOptions(ort, options)
check_status(ort, status)
@info "CreateSessionOptions" status options[]

session = Ptr{OrtSession}() |> Ref
status = CreateSession(ort, env[], MODEL_PATH, options[], session)
check_status(ort, status)
@info "CreateSession" status session[]

allocator = Ptr{OrtAllocator}() |> Ref
status = GetAllocatorWithDefaultOptions(ort, allocator)
check_status(ort, status)
@info "GetAllocatorWithDefaultOptions" status allocator[]

memory_info = Ptr{OrtMemoryInfo}() |> Ref
status = CreateCpuMemoryInfo(ort, OrtArenaAllocator, OrtMemTypeDefault, memory_info)
check_status(ort, status)
@info "CreateCpuMemoryInfo" status memory_info[]

input_shape = Clonglong[3, 4, 5]
input_values = fill(Cfloat(1.0), 5, 4, 3) # ONNX uses row-major order
input_tensor = Ptr{OrtValue}() |> Ref   
status = CreateTensorWithDataAsOrtValue(ort, memory_info[], input_values, sizeof(input_values), input_shape, length(input_shape), ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, input_tensor)
check_status(ort, status)
@info "CreateTensorWithDataAsOrtValue" status input_tensor[]

input_tensors = [input_tensor[]]
output_tensor = Ptr{OrtValue}() 
output_tensors = [output_tensor]
num_outputs = length(output_tensors)
input_names = [pointer(INPUT_NAME)] # Needs GC preserve
output_names = [pointer(OUTPUT_NAME)] # Needs GC preserve
output_tensors = Ptr{OrtValue}() |> Ref

@preserve INPUT_NAME OUTPUT_NAME begin 
    status = Run(ort, session[], C_NULL, input_names, input_tensors, length(input_tensors), output_names, length(output_names), output_tensors)
end
check_status(ort, status)   
@info "Run" status output_tensors[]

