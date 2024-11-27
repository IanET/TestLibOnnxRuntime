using LibOnnxRuntime

GetApi(base, version) = (@ccall $(base.GetApi)(version::UInt32)::Ptr{OrtApi}) |> unsafe_load
CreateEnv(ort, level, status, env) = @ccall $(ort.CreateEnv)(level::Cint, status::Cstring, env::Ptr{Ptr{OrtEnv}})::OrtStatusPtr
GetErrorMessage(ort, status) = (@ccall $(ort.GetErrorMessage)(status::OrtStatusPtr)::Cstring) |> unsafe_string
GetErrorCode(ort, status) = @ccall $(ort.GetErrorCode)(status::OrtStatusPtr)::Cint
CreateSessionOptions(ort, options) = @ccall $(ort.CreateSessionOptions)(options::Ptr{Ptr{OrtSessionOptions}})::OrtStatusPtr

# CreateSession(ort, env, model_path, options, session) = @ccall $(ort.CreateSession)(env::Ptr{OrtEnv}, model_path::Cstring, options::Ptr{OrtSessionOptions}, session::Ptr{Ptr{OrtSession}})::OrtStatusPtr
# CreateMemoryInfo(ort, name, type, id, mem_type, memory_info) = @ccall $(ort.CreateMemoryInfo)(name::Cstring, type::OrtAllocatorType, id::Cint, mem_type::OrtMemType, memory_info::Ptr{Ptr{OrtMemoryInfo}})::OrtStatusPtr
# Run(session, run_options, input_names, inputs, input_len, output_names, output_names_len, outputs) = @ccall $(ort.Run)()::OrtStatusPtr


base = OrtGetApiBase() |> unsafe_load
ort = GetApi(base, ORT_API_VERSION)
env = Ptr{OrtEnv}(C_NULL) |> Ref
status = CreateEnv(ort, ORT_LOGGING_LEVEL_VERBOSE, "Test", env)
@info "CreateEnv" status env[]

if status != OrtStatusPtr(0)
    msg = GetErrorMessage(ort, status)
    code = GetErrorCode(ort, status)
    println("Status: $code $msg")
end

options = Ptr{OrtSessionOptions}(0) |> Ref
status = CreateSessionOptions(ort, options)
@info "CreateSessionOptions" status options[]
session = Ptr{OrtSession}(C_NULL) |> Ref

# TBD

# status = CreateSession(ort, env[], "./path_to_model", options[], session)
# status = Run(session, run_options, input_names, inputs, input_len, output_names, output_names_len, outputs)