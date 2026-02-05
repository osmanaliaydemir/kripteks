import os
import sys
import traceback
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, List, Any
import uvicorn
from pathlib import Path
from dotenv import load_dotenv

# Path setup: Add ChatDev_Repo to sys.path so we can import its modules
current_dir = Path(__file__).parent
repo_path = current_dir / "ChatDev_Repo"
sys.path.append(str(repo_path))

# ChatDev SDK imports
try:
    from runtime.sdk import run_workflow
except ImportError as e:
    print(f"ChatDev SDK import error: {e}")
    run_workflow = None

load_dotenv()

app = FastAPI(title="Kripteks AI Bridge (ChatDev 2.0)")

class WorkflowRequest(BaseModel):
    workflow_yaml: str
    task_prompt: str
    variables: Optional[Dict[str, Any]] = None

class WorkflowResponse(BaseModel):
    status: str
    result: Optional[str] = None
    meta_info: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

@app.get("/health")
async def health_check():
    return {"status": "healthy", "sdk_loaded": run_workflow is not None}

@app.post("/run-workflow", response_model=WorkflowResponse)
async def run_chatdev_workflow(request: WorkflowRequest):
    if not run_workflow:
        return WorkflowResponse(status="error", error="ChatDev SDK could not be loaded")
    
    try:
        # ChatDev 2.0 expects the YAML to be in a specific directory or absolute path
        yaml_file = request.workflow_yaml
        if not os.path.isabs(yaml_file):
            # Check if it exists in our local workflows or ChatDev's instances
            local_path = current_dir / "workflows" / yaml_file
            if local_path.exists():
                yaml_file = str(local_path)

        print(f"Running workflow: {yaml_file} with prompt: {request.task_prompt}")
        
        # Inject environment variables into ChatDev variables if not provided
        vars_to_pass = request.variables or {}
        
        # Check if we should use Gemini or OpenAI key
        # We can look into the YAML to see the provider, but easier to just provide both if available
        # or map them to a generic API_KEY if needed.
        # ChatDev 2.0 often uses ${API_KEY} in YAML configs.
        
        if "API_KEY" not in vars_to_pass:
            # Simple heuristic: if workflow name contains 'gemini' or we detect it later
            # For now, let's just use the OpenAI key as default, but if it fails or if we want gemini:
            # Better: Pass both under specific names and let YAML choose, 
            # or detect 'gemini' in the task or yaml content.
            
            # Since we switched sentiment_analysis.yaml to gemini, let's prioritize it if OPENAI fails
            # or if the user asks for it. 
            # Actually, let's just pass both or determine based on the YAML file.
            
            is_gemini = "gemini" in yaml_file.lower() or "gemini" in str(request.variables or {}).lower()
            is_deepseek = "deepseek" in yaml_file.lower() or "deepseek" in str(request.variables or {}).lower()
            
            if is_gemini:
                vars_to_pass["API_KEY"] = os.getenv("GEMINI_API_KEY")
            elif is_deepseek:
                vars_to_pass["API_KEY"] = os.getenv("DEEPSEEK_API_KEY")
            else:
                vars_to_pass["API_KEY"] = os.getenv("OPENAI_API_KEY")

        if "BASE_URL" not in vars_to_pass:
            vars_to_pass["BASE_URL"] = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")

        result = run_workflow(
            yaml_file=yaml_file,
            task_prompt=request.task_prompt,
            variables=vars_to_pass
        )
        
        final_text = ""
        if result.final_message:
            final_text = result.final_message.text_content()
        
        print(f"Workflow Success: {final_text[:100]}...")
        
        return WorkflowResponse(
            status="success",
            result=final_text,
            meta_info={
                "session_name": result.meta_info.session_name,
                "output_dir": str(result.meta_info.output_dir),
                "token_usage": result.meta_info.token_usage
            }
        )
    except Exception as e:
        import traceback
        error_msg = f"{str(e)}"
        print(f"Workflow Error: {error_msg}\n{traceback.format_exc()}")
        return WorkflowResponse(status="error", error=error_msg)

if __name__ == "__main__":
    # Ensure WareHouse exists (ChatDev requirement)
    os.makedirs("WareHouse", exist_ok=True)
    uvicorn.run(app, host="0.0.0.0", port=8000)
