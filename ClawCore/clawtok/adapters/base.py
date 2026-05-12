"""PlatformAdapter ABC. Spec reference: §3.1"""

from __future__ import annotations
from abc import ABC, abstractmethod
from clawtok.models import InboundMessage, Event


class PlatformAdapter(ABC):
    @abstractmethod
    async def parse_request(self, raw_request) -> InboundMessage: ...

    @abstractmethod
    async def send_events(self, events: list[Event], raw_response) -> None: ...
