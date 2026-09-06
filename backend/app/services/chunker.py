import re
from typing import List

class RecursiveCharacterTextSplitter:
    def __init__(self, chunk_size: int = 800, chunk_overlap: int = 100):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.separators = ["\n\n", "\n", " ", ""]

    def _split_text(self, text: str, separators: List[str]) -> List[str]:
        if len(text) <= self.chunk_size:
            return [text]
            
        separator = separators[-1]
        for s in separators:
            if s == "":
                separator = s
                break
            if s in text:
                separator = s
                break
                
        if separator:
            splits = text.split(separator)
        else:
            splits = list(text)
            
        final_chunks = []
        current_chunk = []
        current_len = 0
        
        for s in splits:
            if len(s) > self.chunk_size:
                if current_chunk:
                    final_chunks.append(separator.join(current_chunk))
                    current_chunk = []
                    current_len = 0
                
                next_separators = separators[separators.index(separator) + 1:] if separator in separators else [""]
                if not next_separators:
                    next_separators = [""]
                
                final_chunks.extend(self._split_text(s, next_separators))
                continue
                
            s_len_with_sep = len(s) + (len(separator) if current_chunk else 0)
            
            if current_len + s_len_with_sep > self.chunk_size and current_chunk:
                final_chunks.append(separator.join(current_chunk))
                
                overlap_len = 0
                new_chunk = []
                for item in reversed(current_chunk):
                    if overlap_len + len(item) <= self.chunk_overlap:
                        new_chunk.insert(0, item)
                        overlap_len += len(item) + len(separator)
                    else:
                        break
                current_chunk = new_chunk
                current_len = sum(len(c) for c in current_chunk) + (len(separator) * max(0, len(current_chunk) - 1))
            
            current_chunk.append(s)
            current_len += len(s) + (len(separator) if len(current_chunk) > 1 else 0)
            
        if current_chunk:
            final_chunks.append(separator.join(current_chunk))
            
        return [c.strip() for c in final_chunks if c.strip()]

    def split_text(self, text: str) -> List[str]:
        return self._split_text(text, self.separators)
