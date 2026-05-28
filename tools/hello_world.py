"""Simple hello world tool for testing."""

from typing import Optional
from pydantic import BaseModel, Field
from ibm_watsonx_orchestrate.agent_builder.tools import tool


class ErrorDetails(BaseModel):
    """Error details for tool responses."""
    error_code: str = Field(description="Error code")
    error_message: str = Field(description="Error message")


class ToolResponse(BaseModel):
    """Generic tool response wrapper."""
    tool_output: Optional[str] = Field(default=None, description="Tool output")
    error_details: Optional[ErrorDetails] = Field(default=None, description="Error details")


@tool
def hello_world(name: str = "World") -> ToolResponse:
    """Returns a simple greeting message.
    
    Args:
        name: The name to greet. Defaults to "World".
    
    Returns:
        ToolResponse with greeting message or error details.
    """
    try:
        greeting = f"Hello, {name}! This is a test agent from Watsonx Orchestrate."
        return ToolResponse(tool_output=greeting)
    except Exception as e:
        return ToolResponse(
            error_details=ErrorDetails(
                error_code="GREETING_ERROR",
                error_message=str(e)
            )
        )
