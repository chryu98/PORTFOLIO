package com.busanbank.card.card.mybatis;


import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.sql.Blob;
import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@MappedTypes(byte[].class)
@MappedJdbcTypes(JdbcType.BLOB)
public class BlobToBytesTypeHandler extends BaseTypeHandler<byte[]> {

    @Override
    public void setNonNullParameter(PreparedStatement ps, int i, byte[] parameter, JdbcType jdbcType) throws SQLException {
        ps.setBytes(i, parameter); // BLOB 쓰기
    }

    @Override
    public byte[] getNullableResult(ResultSet rs, String columnName) throws SQLException {
        Blob blob = rs.getBlob(columnName);
        return toBytes(blob);
    }

    @Override
    public byte[] getNullableResult(ResultSet rs, int columnIndex) throws SQLException {
        Blob blob = rs.getBlob(columnIndex);
        return toBytes(blob);
    }

    @Override
    public byte[] getNullableResult(CallableStatement cs, int columnIndex) throws SQLException {
        Blob blob = cs.getBlob(columnIndex); // ← 위치 인자만!
        return toBytes(blob);
    }

    private byte[] toBytes(Blob blob) throws SQLException {
        if (blob == null) return null;

        try (InputStream is = blob.getBinaryStream();
             ByteArrayOutputStream out = new ByteArrayOutputStream(8192)) {

            byte[] buf = new byte[8192];
            int n;
            while ((n = is.read(buf)) != -1) {
                out.write(buf, 0, n);
            }
            return out.toByteArray();

        } catch (IOException e) {
            // read()에서 발생하는 IO 예외를 SQLException으로 래핑
            throw new SQLException("Failed to read BLOB stream", e);
        } finally {
            try { blob.free(); } catch (Exception ignore) {}
        }
    }
}