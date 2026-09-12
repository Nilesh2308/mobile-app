import io
from pypdf import PdfReader
from docx import Document

class DocumentParser:
    @staticmethod
    def parse_pdf(file_bytes: bytes) -> str:
        reader = PdfReader(io.BytesIO(file_bytes))
        text = ""
        for page in reader.pages:
            try:
                extracted = page.extract_text(extraction_mode="layout")
            except Exception:
                extracted = page.extract_text()
            if extracted:
                text += extracted + "\n"
        return text

    @staticmethod
    def parse_docx(file_bytes: bytes) -> str:
        doc = Document(io.BytesIO(file_bytes))
        return "\n".join([para.text for para in doc.paragraphs])

    @staticmethod
    def parse_txt(file_bytes: bytes) -> str:
        try:
            return file_bytes.decode("utf-8")
        except UnicodeDecodeError:
            # Fallback for different encodings if needed
            return file_bytes.decode("latin-1")

    @classmethod
    def parse(cls, file_bytes: bytes, filename: str) -> str:
        ext = filename.split(".")[-1].lower()
        if ext == "pdf":
            return cls.parse_pdf(file_bytes)
        elif ext in ["doc", "docx"]:
            return cls.parse_docx(file_bytes)
        elif ext in ["txt", "md", "csv"]:
            return cls.parse_txt(file_bytes)
        else:
            raise ValueError(f"Unsupported file type: {ext}")
