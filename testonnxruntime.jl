using LibOnnxRuntime

GetApi(base, version) = (@ccall $(base.GetApi)(version::UInt32)::Ptr{OrtApi}) |> unsafe_load
CreateEnv(ort, level, status, env) = @ccall $(ort.CreateEnv)(level::Cint, status::Cstring, env::Ptr{Ptr{OrtEnv}})::OrtStatusPtr
GetErrorMessage(ort, status) = (@ccall $(ort.GetErrorMessage)(status::OrtStatusPtr)::Cstring) |> unsafe_string
GetErrorCode(ort, status) = @ccall $(ort.GetErrorCode)(status::OrtStatusPtr)::Cint
CreateSessionOptions(ort, options) = @ccall $(ort.CreateSessionOptions)(options::Ptr{Ptr{OrtSessionOptions}})::OrtStatusPtr

base = OrtGetApiBase() |> unsafe_load
ort = GetApi(base, ORT_API_VERSION)
env = Ptr{OrtEnv}(0) |> Ref
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

# TBD