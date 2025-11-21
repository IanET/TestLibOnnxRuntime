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
CreateTensorWithDataAsOrtValue(ort, allocator, data_ptr, data_length, shape_ptr, shape_length, type, value) = @ccall $(ort.CreateTensorWithDataAsOrtValue)(allocator::Ptr{OrtAllocator}, data_ptr::Ptr{Cvoid}, data_length::Csize_t, shape_ptr::Ptr{Int64}, shape_length::Csize_t, type::ONNXTensorElementDataType, value::Ptr{Ptr{OrtValue}})::OrtStatusPtr

function check_status(ort, status)
    if status != OrtStatusPtr(0)
        msg = GetErrorMessage(ort, status)
        code = GetErrorCode(ort, status)
        println("Status: $code $msg")
    end
end

base = OrtGetApiBase() |> unsafe_load
ort = GetApi(base, ORT_API_VERSION)
env = Ptr{OrtEnv}(0) |> Ref
status = CreateEnv(ort, ORT_LOGGING_LEVEL_VERBOSE, "Test", env)
check_status(ort, status)
@info "CreateEnv" status env[]

options = Ptr{OrtSessionOptions}(0) |> Ref
status = CreateSessionOptions(ort, options)
check_status(ort, status)
@info "CreateSessionOptions" status options[]

session = Ptr{OrtSession}(0) |> Ref
status = CreateSession(ort, env[], MODEL_PATH, options[], session)
check_status(ort, status)

allocator = Ptr{OrtAllocator}(0) |> Ref
status = GetAllocatorWithDefaultOptions(ort, allocator)
check_status(ort, status)

# GC.@preserve INPUT_NAME OUTPUT_NAME begin
    input_names = [pointer(INPUT_NAME)]
    input_shape = Clonglong[3, 4, 5]
    input_values = fill(Cfloat(1.0), 5, 4, 3) # ONNX uses row-major order
    input_tensor = Ptr{OrtValue}(0) |> Ref   
    status = CreateTensorWithDataAsOrtValue(ort, allocator[], input_values, sizeof(input_values), input_shape, length(input_shape), ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT, input_tensor)
    check_status(ort, status)
# end