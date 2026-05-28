"""Simple goodbye world tool for test2 agent."""

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
def goodbye_world(name: str = "World") -> ToolResponse:
    """Returns a farewell message.
    
    Args:
        name: The name to say goodbye to. Defaults to "World".
    
    Returns:
        ToolResponse with farewell message or error details.
    """
    try:
        farewell = f"Goodbye, {name}! Thanks for testing the test2 agent from Watsonx Orchestrate."
        return ToolResponse(tool_output=farewell)
    except Exception as e:
        return ToolResponse(
            error_details=ErrorDetails(
                error_code="FAREWELL_ERROR",
                error_message=str(e)
            )
        )
